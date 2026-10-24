import AppKit
import SwiftUI

struct HUDIsland: View {
    fileprivate static let compactInset: CGFloat = 14
    fileprivate static let cardInset: CGFloat = 18
    fileprivate static let bottomInset: CGFloat = 14
    fileprivate static let orbSize: CGFloat = 34

    let content: HUDContent?
    let hud: HUDController
    let layout: HUDLayout

    var body: some View {
        switch content {
        case nil:
            Color.clear
                .frame(width: layout.restWidth, height: layout.restHeight)

        case let .listening(badge, isHandsFree):
            CompactRow(layout: layout) {
                HStack(spacing: 5) {
                    IslandSymbol(name: isHandsFree ? "lock.fill" : "mic.fill")
                        .foregroundStyle(Palette.danger)

                    Text(hud.listeningSince, style: .timer)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            } trailing: {
                LevelBars(levels: hud.levels)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Waft is listening")
            .accessibilityValue(listeningState(badge: badge, isHandsFree: isHandsFree))

        case let .working(label):
            WorkingCard(label: label, appearedAt: hud.workingSince, steppedAt: hud.stepChangedAt, layout: layout)

        case let .message(message):
            if hud.showsCompactMessage {
                PastedRow(message: message, hasCopied: hud.hasCopied, layout: layout, copy: hud.copyMessage)
            } else {
                MessageCard(message: message, hasCopied: hud.hasCopied, layout: layout, copy: hud.copyMessage)
            }
        }
    }

    private func listeningState(badge: String, isHandsFree: Bool) -> String {
        guard isHandsFree else { return badge }

        return [badge, String(localized: "Hands-free")].formatted(.list(type: .and, width: .narrow))
    }
}

private struct CompactRow<Leading: View, Trailing: View>: View {
    let layout: HUDLayout
    @ViewBuilder let leading: Leading
    @ViewBuilder let trailing: Trailing

    var body: some View {
        IslandRow(gap: layout.gap) {
            leading
                .padding(.leading, HUDIsland.compactInset)

            trailing
                .padding(.trailing, HUDIsland.compactInset)
        }
        .font(.hudSymbol)
        .foregroundStyle(.white)
        .frame(height: layout.topHeight)
    }
}

private struct WorkingCard: View {
    let label: String
    let appearedAt: Date
    let steppedAt: Date
    let layout: HUDLayout

    var body: some View {
        VStack(spacing: 8) {
            IslandOrb(size: HUDIsland.orbSize, appearedAt: appearedAt, pulsedAt: steppedAt)

            ShimmeringText(text: label)
                .font(.hudCaption)
                .id(label)
                .transition(.opacity)
        }
        .motion(Motion.islandContent, value: label)
        .frame(width: layout.spanWidth)
        .padding(.top, layout.isFloating ? HUDIsland.bottomInset : layout.topHeight)
        .padding(.bottom, HUDIsland.bottomInset)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}

private struct PastedRow: View {
    let message: HUDMessage
    let hasCopied: Bool
    let layout: HUDLayout
    let copy: () -> Void

    private var spokenText: String {
        [message.title, message.detail].compactMap(\.self).joined(separator: "\n")
    }

    var body: some View {
        CompactRow(layout: layout) {
            IslandSymbol(name: "checkmark.circle.fill")
                .foregroundStyle(Palette.success)
        } trailing: {
            PastedStatus(message: message, hasCopied: hasCopied)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(spokenText)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default, copy)
        .accessibilityAction(named: "Copy", copy)
    }
}

private struct MessageCard: View {
    private static let longTitleLength = 140
    private static let textSpacing: CGFloat = 4
    private static let titleFont = NSFont.systemFont(ofSize: 14, weight: .medium)
    private static let detailFont = NSFont.systemFont(ofSize: 12)

    let message: HUDMessage
    let hasCopied: Bool
    let layout: HUDLayout
    let copy: () -> Void

    private var isLong: Bool {
        message.title.count > Self.longTitleLength
    }

    private var measuredLines: [(String, NSFont)] {
        var lines = [(message.title, Self.titleFont)]

        if let detail = message.detail {
            lines.append((detail, Self.detailFont))
        }

        return lines
    }

    private var detailStyle: AnyShapeStyle {
        guard message.kind == .pasted else { return AnyShapeStyle(.secondary) }

        return AnyShapeStyle(Palette.warning)
    }

    private var fade: LinearGradient {
        let end = isLong ? 0.25 : 1

        return LinearGradient(
            stops: [
                .init(color: .black, location: 0),
                .init(color: .black, location: 0.6),
                .init(color: .black.opacity(end), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom,
        )
    }

    var body: some View {
        if message.isCopyable {
            card
                .contentShape(Rectangle())
                .onTapGesture(perform: copy)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
                .accessibilityAction(named: "Copy", copy)
        } else {
            card
                .accessibilityElement(children: .combine)
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            IslandRow(gap: layout.gap) {
                symbol
                    .padding(.leading, HUDIsland.cardInset)

                action
                    .padding(.trailing, HUDIsland.cardInset)
            }
            .font(.hudSymbol)
            .frame(height: layout.topHeight)

            VStack(alignment: .leading, spacing: Self.textSpacing) {
                Text(message.title)
                    .font(Font(Self.titleFont))
                    .lineLimit(3)
                    .mask(fade)
                    .contentDirection(of: message.title)

                if let detail = message.detail {
                    Text(detail)
                        .font(Font(Self.detailFont))
                        .foregroundStyle(detailStyle)
                        .lineLimit(3)
                }
            }
            .frame(width: TextWidth.fitting(measuredLines), alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, HUDIsland.cardInset)
            .padding(.bottom, HUDIsland.bottomInset)
        }
        .foregroundStyle(.white)
    }

    @ViewBuilder
    private var symbol: some View {
        switch message.kind {
        case .pasted:
            IslandSymbol(name: "checkmark.circle.fill")
                .foregroundStyle(Palette.success)

        case .copied:
            IslandSymbol(name: "doc.on.clipboard.fill")

        case .information:
            IslandSymbol(name: "info.circle")

        case .warning:
            IslandSymbol(name: "exclamationmark.triangle.fill")
                .foregroundStyle(Palette.warning)
        }
    }

    @ViewBuilder
    private var action: some View {
        switch message.kind {
        case .pasted:
            ZStack(alignment: .trailing) {
                PastedStatus(message: message, hasCopied: hasCopied)
                    .hidden()

                IslandSymbol(name: hasCopied ? "checkmark" : "doc.on.doc")
                    .foregroundStyle(hasCopied ? Palette.success : .white)
            }
            .accessibilityHidden(true)

        case .copied:
            PasteKeys()

        case .information, .warning:
            EmptyView()
        }
    }
}

private enum TextWidth {
    private static let maximum: CGFloat = 440

    static func fitting(_ texts: [(String, NSFont)]) -> CGFloat {
        let widest = texts.reduce(0) { widest, text in
            text.0.split(separator: "\n").reduce(widest) { widest, line in
                max(widest, (String(line) as NSString).size(withAttributes: [.font: text.1]).width)
            }
        }

        return min(maximum, ceil(widest) + 1)
    }
}
