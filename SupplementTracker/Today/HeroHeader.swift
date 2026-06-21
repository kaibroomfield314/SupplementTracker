import SwiftUI
import PhotosUI

struct HeroHeader: View {
    @AppStorage(UserPreferenceKeys.userName) private var userName: String = ""
    @AppStorage(UserPreferenceKeys.avatarData) private var avatarData: Data = Data()

    @State private var photoSelection: PhotosPickerItem?

    private let date = Date.now

    var body: some View {
        HStack(spacing: 14) {
            avatarView
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingLine)
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.top, 8)
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

    private var greetingLine: String {
        let hour = Calendar.current.component(.hour, from: date)
        let base: String
        switch hour {
        case 5..<12: base = "Good morning"
        case 12..<17: base = "Good afternoon"
        case 17..<22: base = "Good evening"
        default: base = "Hey, night owl"
        }
        let trimmed = userName.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? base : "\(base), \(trimmed)"
    }

    @ViewBuilder
    private var avatarView: some View {
        PhotosPicker(selection: $photoSelection, matching: .images) {
            if let img = avatarUIImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 2))
            } else {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.gradient)
                        .frame(width: 52, height: 52)
                    Text(initials)
                        .font(.headline)
                        .foregroundStyle(.white)
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
        guard !trimmed.isEmpty else { return "👤" }
        let parts = trimmed.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.count > 1 ? (parts.last?.first.map(String.init) ?? "") : ""
        return (first + last).uppercased()
    }
}
