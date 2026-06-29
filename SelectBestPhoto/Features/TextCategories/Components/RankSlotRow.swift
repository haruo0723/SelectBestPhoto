import SwiftUI

struct RankSlotRow: View {
    let slot: TextRankingSlotState
    let action: () -> Void
    let clearAction: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                rankBadge

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(slot.rank)位")
                        .font(.headline)
                    Text(slot.candidate?.name ?? "候補を選択")
                        .font(.subheadline)
                        .foregroundStyle(slot.candidate == nil ? .secondary : .primary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                if slot.candidate == nil {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.tint)
                } else {
                    Button(action: clearAction) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("\(slot.rank)位の選択を解除")
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(slot.accessibilityLabel)
    }

    private var rankBadge: some View {
        ZStack {
            Circle()
                .fill(slot.candidate == nil ? Color.secondary.opacity(0.14) : Color.accentColor.opacity(0.18))
                .frame(width: 44, height: 44)

            Text("\(slot.rank)")
                .font(.headline)
                .foregroundStyle(slot.candidate == nil ? Color.secondary : Color.accentColor)
        }
        .accessibilityHidden(true)
    }
}
