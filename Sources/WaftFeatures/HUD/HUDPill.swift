import AppKit
import SwiftUI

struct HUDPill: View {
    fileprivate static let spacing: CGFloat = 10
    fileprivate static let titleFont = NSFont.systemFont(ofSize: 14, weight: .medium)
    fileprivate static let detailFont = NSFont.systemFont(ofSize: 12)

    private let content: HUDContent
    private let levels: [Float]

    init(content: HUDContent, levels: [Float]) {
        self.content = content
        self.levels = levels
    }

    var body: some View {
        switch content {
        case let .listening(badge, isHandsFree):
            ListeningPill(levels: levels, badge: badge, isHandsFree: isHandsFree)
        case let .working(label):
            WorkingPill(label: label)
        case let .message(message):
            MessagePill(message: message)
        }
    }
}

private struct ListeningPill: View {
    let levels: [Float]
    let badge: String?
    let isHandsFree: Bool

    private var state: String {
        let handsFree = isHandsFree ? String(localized: "Hands-free") : nil

        return [badge, handsFree].compactMap(\.self).formatted(.list(type: .and, width: .narrow))
    }

    var body: some View {
        HStack(spacing: HUDPill.spacing) {
            Image(systemName: "mic.fill")
                .foregroundStyle(Palette.danger)

            LevelBars(levels: levels)

            if let badge {
                Text(badge)
                    .font(.hudBadge)
                    .foregroundStyle(.secondary)
            }

            if isHandsFree {
                Label("Hands-free", systemImage: "lock.fill")
                    .font(.hudBadge)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
        .animation(Motion.feedback, value: isHandsFree)
        .font(.hudSymbol)
        .hudBackground()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Waft is listening")
        .accessibilityValue(state)
    }
}

private struct WorkingPill: View {
    let label: String

    var body: some View {
        HStack(spacing: HUDPill.spacing) {
            Image(systemName: "waveform")
                .symbolEffect(.variableColor.iterative, options: .repeating)
                .accessibilityHidden(true)

            Text(label)
                .font(Font(HUDPill.titleFont))
        }
        .font(.hudSymbol)
        .hudBackground()
        .accessibilityElement(children: .combine)
    }
}

private struct MessagePill: View {
    private static let maximumTextWidth: CGFloat = 520

    let message: HUDMessage

    private var symbolName: String {
        switch message.kind {
        case .pasted: "checkmark.circle.fill"
        case .copied: "doc.on.clipboard"
        case .information: "info.circle"
        case .warning: "exclamationmark.triangle.fill"
        }
    }

    private var symbolColor: Color {
        switch message.kind {
        case .pasted: Palette.success
        case .copied, .information: .secondary
        case .warning: Palette.warning
        }
    }

    private var textWidth: CGFloat {
        var widest = width(of: message.title, font: HUDPill.titleFont)

        if let detail = message.detail {
            widest = max(widest, width(of: detail, font: HUDPill.detailFont))
        }

        return min(Self.maximumTextWidth, ceil(widest) + 1)
    }

    var body: some View {
        HStack(spacing: HUDPill.spacing) {
            Image(systemName: symbolName)
                .font(.hudMessageSymbol)
                .foregroundStyle(symbolColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Metrics.labelSpacing) {
                Text(message.title)
                    .font(Font(HUDPill.titleFont))
                    .lineLimit(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentDirection(of: message.title)

                if let detail = message.detail {
                    Text(detail)
                        .font(Font(HUDPill.detailFont))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: textWidth, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        .hudBackground()
        .accessibilityElement(children: .combine)
    }

    private func width(of text: String, font: NSFont) -> CGFloat {
        text.split(separator: "\n").reduce(0) { widest, line in
            max(widest, (String(line) as NSString).size(withAttributes: [.font: font]).width)
        }
    }
}

private struct LevelBars: View {
    let levels: [Float]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(levels.indices, id: \.self) { index in
                Capsule()
                    .frame(width: 3.5, height: 4 + 18 * CGFloat(levels[index]))
            }
        }
        .frame(height: 22)
        .animation(Motion.meter, value: levels)
    }
}
