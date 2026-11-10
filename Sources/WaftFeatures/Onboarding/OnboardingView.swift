import SwiftUI
import WaftCore

struct OnboardingView: View {
    private static let topInset: CGFloat = 56
    private static let sideInset: CGFloat = 72
    private static let size = CGSize(width: 640, height: 540)

    let model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            step
                .id(model.onboarding.step)
                .transition(StepTransition())
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, Self.topInset)
                .padding(.horizontal, Self.sideInset)

            OnboardingFooter(onboarding: model.onboarding)
        }
        .motion(Motion.page, value: model.onboarding.step)
        .frame(width: Self.size.width, height: Self.size.height)
        .windowChrome()
    }

    @ViewBuilder
    private var step: some View {
        switch model.onboarding.step {
        case .welcome:
            WelcomeStep(keyTitle: model.settings.settings.pushToTalkKey.title, start: model.settings.settings.dictationStart)
        case .microphone:
            PermissionStep(permission: .microphone, monitor: model.permissions)
        case .accessibility:
            PermissionStep(permission: .accessibility, monitor: model.permissions)
        case .practice:
            PracticeStep(model: model)
        case .usage:
            UsageStep()
        case .done:
            DoneStep(model: model)
        }
    }
}

private struct OnboardingFooter: View {
    private static let horizontalInset: CGFloat = 28

    let onboarding: OnboardingModel

    private var primaryTitle: LocalizedStringKey {
        switch (onboarding.pendingStatus, onboarding.step) {
        case (.notDetermined, _): "Allow Access…"
        case (.denied, _): "Open System Settings"
        case (_, .welcome): "Get Started"
        case (_, .done): "Done"
        case (_, .microphone), (_, .accessibility), (_, .practice), (_, .usage): "Continue"
        }
    }

    var body: some View {
        ZStack {
            PageDots(steps: onboarding.steps, current: onboarding.step)

            HStack {
                Button("Back") { onboarding.goBack() }
                    .opacity(onboarding.canGoBack ? 1 : 0)
                    .disabled(!onboarding.canGoBack)
                    .accessibilityHidden(!onboarding.canGoBack)

                Spacer()

                actions
            }
        }
        .controlSize(.large)
        .padding(.horizontal, Self.horizontalInset)
        .padding(.top, Metrics.accessorySpacing)
        .padding(.bottom, Metrics.windowPadding)
    }

    @ViewBuilder
    private var actions: some View {
        if onboarding.step == .usage {
            Button("Don't Share") { onboarding.answerUsage(shares: false) }
            Button("Share") { onboarding.answerUsage(shares: true) }
        } else {
            Button(primaryTitle) {
                Task { await onboarding.proceed() }
            }
            .buttonStyle(PushButtonStyle(isProminent: true))
            .keyboardShortcut(.defaultAction)
        }
    }
}

private struct PageDots: View {
    let steps: [OnboardingModel.Step]
    let current: OnboardingModel.Step

    private var position: Int {
        steps.prefix { $0 != current }.count + 1
    }

    var body: some View {
        if steps.count > 1 {
            HStack(spacing: Metrics.inlineSpacing) {
                ForEach(steps, id: \.self) { step in
                    Capsule()
                        .fill(fill(of: step))
                        .frame(width: step == current ? 18 : 7, height: 7)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Step \(position) of \(steps.count)")
        }
    }

    private func fill(of step: OnboardingModel.Step) -> AnyShapeStyle {
        guard step == current else { return AnyShapeStyle(.quaternary) }

        return AnyShapeStyle(Palette.accent)
    }
}

private struct StepTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .opacity(phase.isIdentity ? 1 : 0)
            .motionOffset(y: phase.value * -8)
    }
}
