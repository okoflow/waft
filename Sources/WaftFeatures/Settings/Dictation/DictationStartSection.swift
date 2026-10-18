import SwiftUI
import WaftCore

struct DictationStartSection: View {
    let settings: SettingsModel

    var body: some View {
        SettingsGroup("How to start") {
            HStack(alignment: .top, spacing: Metrics.controlSpacing) {
                ForEach(DictationStart.allCases, id: \.self) { start in
                    PickerCard(
                        start.title,
                        detail: start.detail,
                        isSelected: settings.settings.dictationStart == start,
                    ) {
                        settings.settings.dictationStart = start
                    } preview: {
                        StartDiagram(start: start)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct StartDiagram: View {
    let start: DictationStart

    var body: some View {
        HStack(spacing: 6) {
            Track()

            switch start {
            case .hold:
                Press(width: 64)

            case .tap:
                HStack(spacing: 0) {
                    Tap()
                    Capsule().fill(Palette.accent).frame(width: 46, height: 2)
                    Tap()
                }

            case .holdOrDoubleTap:
                Press(width: 34)
                Track().frame(width: 10)

                HStack(spacing: 9) {
                    Press(width: 15, height: 15)
                    Press(width: 15, height: 15)
                }
            }

            Track()
        }
        .padding(.horizontal, 10)
        .accessibilityHidden(true)
    }
}

private struct Track: View {
    var body: some View {
        Capsule()
            .fill(Palette.separator)
            .frame(height: 2)
    }
}

private struct Press: View {
    let width: CGFloat
    var height: CGFloat = 22

    var body: some View {
        RoundedRectangle(cornerRadius: height / 4, style: .continuous)
            .fill(Palette.accent)
            .frame(width: width, height: height)
    }
}

private struct Tap: View {
    var body: some View {
        Circle()
            .fill(Palette.accent)
            .frame(width: 10, height: 10)
    }
}
