import AppKit
import SwiftUI

struct HUDIsland: View {
    fileprivate static let compactInset: CGFloat = 14
    fileprivate static let cardInset: CGFloat = 18
    fileprivate static let bottomInset: CGFloat = 14
    fileprivate static let textSpacing: CGFloat = 4
    fileprivate static let cardOrbSize: CGFloat = 18
    fileprivate static let titleFont = NSFont.systemFont(ofSize: 14, weight: .medium)
    fileprivate static let detailFont = NSFont.systemFont(ofSize: 12)
    fileprivate static let footnoteFont = NSFont.systemFont(ofSize: 11)

    let content: HUDContent?
    let hud: HUDController
    let layout: HUDLayout

    var body: some View {
        switch content {
        case nil:
            Color.clear
                .frame(width: layout.restWidth, height: layout.restHeight)

        case let .listening(badge, isHandsFree):
            CompactIsland(layout: layout) {
                HStack(spacing: 5) {
                    Image(systemName: isHandsFree ? "lock.fill" : "mic.fill")
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
            if let cleanup = hud.cleanup {
                CleanupCard(label: label, cleanup: cleanup, layout: layout)
            } else {
                TranscribingCard(label: label, layout: layout)
            }

        case let .message(message):
            MessageCard(message: message, hasCopied: hud.hasCopied, layout: layout, copy: hud.copyMessage)
        }
    }

    private func listeningState(badge: String, isHandsFree: Bool) -> String {
        guard isHandsFree else { return badge }

        return [badge, String(localized: "Hands-free")].formatted(.list(type: .and, width: .narrow))
    }
}

private struct CompactIsland<Leading: View, Trailing: View>: View {
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

private struct IslandCard<Leading: View, Trailing: View, Content: View>: View {
    let layout: HUDLayout
    @ViewBuilder let leading: Leading
    @ViewBuilder let trailing: Trailing
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            IslandRow(gap: layout.gap) {
                leading
                    .padding(.leading, HUDIsland.cardInset)

                trailing
                    .font(.hudCaption)
                    .foregroundStyle(.secondary)
                    .padding(.trailing, HUDIsland.cardInset)
            }
            .font(.hudSymbol)
            .frame(height: layout.topHeight)

            content
                .padding(.horizontal, HUDIsland.cardInset)
                .padding(.bottom, HUDIsland.bottomInset)
        }
        .foregroundStyle(.white)
    }
}

private struct TranscribingCard: View {
    let label: String
    let layout: HUDLayout

    var body: some View {
        VStack(spacing: 8) {
            IslandOrb(style: .scanning, size: 34, tint: .white)

            ShimmeringText(text: label)
                .font(.hudCaption)
        }
        .frame(width: layout.spanWidth)
        .padding(.top, layout.topHeight)
        .padding(.bottom, HUDIsland.bottomInset)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}

private struct CleanupCard: View {
    let label: String
    let cleanup: HUDCleanup
    let layout: HUDLayout

    var body: some View {
        IslandCard(layout: layout) {
            IslandOrb(style: .scanning, size: HUDIsland.cardOrbSize, tint: Palette.accent)
        } trailing: {
            Text(cleanup.mode)
        } content: {
            VStack(alignment: .leading, spacing: HUDIsland.textSpacing) {
                Text(cleanup.transcript)
                    .font(Font(HUDIsland.titleFont))
                    .foregroundStyle(.tertiary)
                    .lineLimit(3)
                    .contentDirection(of: cleanup.transcript)

                Text(label)
                    .font(Font(HUDIsland.footnoteFont))
                    .foregroundStyle(.secondary)
            }
            .frame(
                width: TextWidth.fitting([(cleanup.transcript, HUDIsland.titleFont), (label, HUDIsland.footnoteFont)]),
                alignment: .leading,
            )
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct MessageCard: View {
    private static let longTitleLength = 140

    let message: HUDMessage
    let hasCopied: Bool
    let layout: HUDLayout
    let copy: () -> Void

    private var isLong: Bool {
        message.title.count > Self.longTitleLength
    }

    private var footer: LocalizedStringKey? {
        guard message.isCopyable else { return nil }
        guard !hasCopied else { return "Copied" }

        return isLong ? "Click to copy all" : "Click to copy"
    }

    private var measuredLines: [(String, NSFont)] {
        var lines = [(message.title, HUDIsland.titleFont)]

        if let detail = message.detail {
            lines.append((detail, HUDIsland.detailFont))
        }

        return lines
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
        IslandCard(layout: layout) {
            symbol
        } trailing: {
            EmptyView()
        } content: {
            VStack(alignment: .leading, spacing: HUDIsland.textSpacing) {
                Text(message.title)
                    .font(Font(HUDIsland.titleFont))
                    .lineLimit(3)
                    .mask(fade)
                    .contentDirection(of: message.title)

                if let detail = message.detail {
                    Text(detail)
                        .font(Font(HUDIsland.detailFont))
                        .foregroundStyle(message.kind == .pasted ? AnyShapeStyle(Palette.warning) : AnyShapeStyle(.secondary))
                        .lineLimit(3)
                }

                if let footer {
                    Text(footer)
                        .font(Font(HUDIsland.footnoteFont))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: TextWidth.fitting(measuredLines), alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var symbol: some View {
        switch message.kind {
        case .pasted:
            IslandOrb(style: .still, size: HUDIsland.cardOrbSize, tint: Palette.success)

        case .copied:
            Image(systemName: "doc.on.clipboard")
                .accessibilityHidden(true)

        case .information:
            Image(systemName: "info.circle")
                .accessibilityHidden(true)

        case .warning:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Palette.warning)
                .accessibilityHidden(true)
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
