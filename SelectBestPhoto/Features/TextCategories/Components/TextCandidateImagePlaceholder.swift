import SwiftUI

struct TextCandidateImagePlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.secondary.opacity(0.12))
            .overlay {
                Image(systemName: "photo")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 52, height: 52)
            .accessibilityLabel("関連画像枠")
    }
}
