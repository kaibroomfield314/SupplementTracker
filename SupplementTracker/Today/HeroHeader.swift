import SwiftUI
import PhotosUI

struct HeroHeader: View {
    @AppStorage(UserPreferenceKeys.userName) private var userName: String = ""
    @AppStorage(UserPreferenceKeys.avatarData) private var avatarData: Data = Data()

    @State private var photoSelection: PhotosPickerItem?

    private let date = Date.now

    var body: some View {
        HStack(spacing: 12) {
            avatarView
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.system(size: 22, weight: .semibold))
                    .lineLimit(1)
                Text(metaLine)
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .tracking(0.4)
            }
            Spacer()
        }
        .onChange(of: photoSelection) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    avatarData = data
                    Haptics.tap(.light)
                }
            }
        }
    }

    private var displayName: String {
        let trimmed = userName.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "Athlete" : trimmed
    }

    private var metaLine: String {
        let day = date.formatted(.dateTime.weekday(.abbreviated)).uppercased()
        let dateStr = date.formatted(.dateTime.month(.abbreviated).day())
        return "\(day) · \(dateStr)"
    }

    @ViewBuilder
    private var avatarView: some View {
        PhotosPicker(selection: $photoSelection, matching: .images) {
            if let img = avatarUIImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(DS.divider, lineWidth: 1)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(initials)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .buttonStyle(.plain)
    }

    private var avatarUIImage: UIImage? {
        guard !avatarData.isEmpty else { return nil }
        return UIImage(data: avatarData)
    }

    private var initials: String {
        let trimmed = userName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "—" }
        let parts = trimmed.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.count > 1 ? (parts.last?.first.map(String.init) ?? "") : ""
        return (first + last).uppercased()
    }
}
