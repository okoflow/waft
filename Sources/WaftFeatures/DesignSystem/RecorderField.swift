import SwiftUI

struct RecorderField: View {
    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    let title: String
    let isEmpty: Bool
    let isRecording: Bool
    let prompt: LocalizedStringKey
    let rejections: Int
    let help: Text
    let label: Text
    let toggle: () -> Void

    var body: some View {
        let shakes = !reducesMotion

        Button(action: toggle) {
            HStack(spacing: Metrics.inlineSpacing) {
                Image(systemName: isRecording ? "record.circle" : "keyboard")
                    .font(.glyph)
                    .foregroundStyle(isRecording ? Palette.accent : Palette.secondaryText)
                    .contentTransition(.symbolEffect(.replace))
                    .accessibilityHidden(true)

                ZStack {
                    if isRecording {
                        Text(prompt)
                            .foregroundStyle(Palette.secondaryText)
                            .transition(.opacity)
                    } else {
                        Text(title)
                            .foregroundStyle(isEmpty ? Palette.secondaryText : Color.primary)
                            .transition(.opacity)
                    }
                }
                .font(.control)
            }
            .padding(.horizontal, Metrics.fieldPadding)
            .frame(minWidth: Metrics.recorderWidth, minHeight: Metrics.controlHeight)
            .modifier(FieldChrome(isFocused: isRecording))
            .contentShape(Rectangle())
            .keyframeAnimator(initialValue: CGFloat.zero, trigger: rejections) { content, offset in
                content.offset(x: shakes ? offset : 0)
            } keyframes: { _ in
                KeyframeTrack {
                    LinearKeyframe(-5, duration: 0.06)
                    LinearKeyframe(5, duration: 0.08)
                    LinearKeyframe(-3, duration: 0.08)
                    SpringKeyframe(0, duration: 0.18, spring: .snappy)
                }
            }
        }
        .buttonStyle(.plain)
        .motion(Motion.feedback, value: isRecording)
        .motion(Motion.feedback, value: title)
        .help(help)
        .accessibilityLabel(label)
        .accessibilityValue(title)
    }
}
