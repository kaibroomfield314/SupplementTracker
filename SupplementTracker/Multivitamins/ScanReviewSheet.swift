import SwiftUI
import SwiftData
import UIKit

struct ScanReviewSheet: View {
    let multivitamin: Multivitamin

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var image: UIImage?
    @State private var showingCamera = false
    @State private var phase: Phase = .idle
    @State private var rows: [DraftRow] = []
    @State private var errorMessage: String?

    enum Phase: Equatable {
        case idle
        case ocr
        case extracting
        case ready
    }

    struct DraftRow: Identifiable, Hashable {
        let id = UUID()
        var name: String
        var amount: Double
        var unit: String
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Scan Label")
                .toolbarTitleDisplayMode(.inline)
                .toolbar { toolbar }
                .sheet(isPresented: $showingCamera) {
                    CameraSheet(image: $image)
                        .ignoresSafeArea()
                }
                .onChange(of: image) { _, newValue in
                    guard let newValue else { return }
                    runPipeline(on: newValue)
                }
                .alert(
                    "Scan failed",
                    isPresented: .constant(errorMessage != nil),
                    presenting: errorMessage
                ) { _ in
                    Button("OK") { errorMessage = nil }
                } message: { msg in
                    Text(msg)
                }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button(rows.isEmpty ? "Save" : "Save \(rows.count)") {
                saveAll()
            }
            .disabled(rows.isEmpty)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .idle where rows.isEmpty:
            EmptyScanState(onCapture: { showingCamera = true })
        case .ocr:
            ProcessingView(message: "Reading the label…")
        case .extracting:
            ProcessingView(message: "Asking Apple Intelligence to make sense of it…")
        case .ready, .idle:
            ReviewList(
                rows: $rows,
                capturedImage: image,
                onScanAnother: { showingCamera = true }
            )
        }
    }

    private func runPipeline(on img: UIImage) {
        errorMessage = nil
        rows = []
        phase = .ocr
        Task {
            do {
                let text = try await OCRService.recognizeText(in: img)
                await MainActor.run { phase = .extracting }
                let extracted = try await IngredientExtractor.extract(from: text)
                await MainActor.run {
                    rows = extracted.map { DraftRow(name: $0.name, amount: $0.amount, unit: $0.unit) }
                    phase = .ready
                }
            } catch {
                await MainActor.run {
                    errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    phase = .idle
                }
            }
        }
    }

    private func saveAll() {
        let startOrder = ((multivitamin.ingredients ?? []).map(\.sortOrder).max() ?? -1) + 1
        for (offset, row) in rows.enumerated() {
            let ingredient = MultivitaminIngredient(
                name: row.name,
                amount: row.amount,
                unit: row.unit,
                sortOrder: startOrder + offset,
                multivitamin: multivitamin
            )
            modelContext.insert(ingredient)
        }
        dismiss()
    }
}

private struct ReviewList: View {
    @Binding var rows: [ScanReviewSheet.DraftRow]
    let capturedImage: UIImage?
    let onScanAnother: () -> Void

    @State private var showingPreview = false

    var body: some View {
        List {
            if let capturedImage {
                Section {
                    Button {
                        showingPreview = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(uiImage: capturedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Original photo")
                                    .font(.subheadline)
                                Text("Tap to view full size")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.tint)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section {
                ForEach($rows) { $row in
                    DraftRowView(row: $row)
                }
                .onDelete { offsets in
                    rows.remove(atOffsets: offsets)
                }
            } header: {
                Text("Found \(rows.count) ingredients")
            } footer: {
                Text("Review and edit each row before saving. Swipe to remove junk lines.")
            }

            Section {
                Button {
                    onScanAnother()
                } label: {
                    Label("Scan another page", systemImage: "camera")
                }
            }
        }
        .sheet(isPresented: $showingPreview) {
            if let capturedImage {
                PhotoPreview(image: capturedImage)
            }
        }
    }
}

private struct PhotoPreview: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView([.horizontal, .vertical]) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
            }
            .navigationTitle("Original photo")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct DraftRowView: View {
    @Binding var row: ScanReviewSheet.DraftRow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Name", text: $row.name)
                .font(.body)
            AmountUnitField(amount: $row.amount, unit: $row.unit)
        }
        .padding(.vertical, 4)
    }
}

private struct ProcessingView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct EmptyScanState: View {
    let onCapture: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Scan a label", systemImage: "doc.text.viewfinder")
        } description: {
            Text("Take a clear, straight-on photo of the Supplement Facts panel. Crop tight if you can.")
        } actions: {
            Button("Open camera", action: onCapture)
                .buttonStyle(.borderedProminent)
        }
    }
}
