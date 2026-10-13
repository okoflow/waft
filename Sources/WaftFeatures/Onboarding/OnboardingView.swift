import SwiftUI
import WaftCore

struct OnboardingView: View {
    private let model: AppModel

    init(model: AppModel) {
        self.model = model
    }

    var body: some View {
        VStack(spacing: 0) {
            step
                .id(model.onboarding.step)
                .transition(StepTransition())
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, Metrics.onboardingTopInset)
                .padding(.horizontal, Metrics.onboardingSideInset)

            OnboardingFooter(onboarding: model.onboarding)
        }
        .animation(Motion.page, value: model.onboarding.step)
        .buttonStyle(PushButtonStyle())
        .reducedMotionPolicy()
        .frame(width: 640, height: 540)
        .background(Palette.window)
        .ignoresSafeArea()
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
        case .done:
            DoneStep(model: model)
        }
    }
}

private struct OnboardingFooter: View {
    let onboarding: OnboardingModel

    private var primaryTitle: LocalizedStringKey {
        switch (onboarding.pendingStatus, onboarding.step) {
        case (.notDetermined, _): "Allow Access…"
        case (.denied, _): "Open System Settings"
        case (_, .welcome): "Get Started"
        case (_, .done): "Done"
        case (_, .microphone), (_, .accessibility), (_, .practice): "Continue"
        }
    }

    var body: some View {
        ZStack {
            PageDots(count: OnboardingModel.Step.allCases.count, current: onboarding.step.rawValue)

            HStack {
                Button("Back") { onboarding.goBack() }
                    .opacity(onboarding.canGoBack ? 1 : 0)
                    .disabled(!onboarding.canGoBack)
                    .accessibilityHidden(!onboarding.canGoBack)

                Spacer()

                Button(primaryTitle) {
                    Task { await onboarding.proceed() }
                }
                .buttonStyle(PushButtonStyle(isProminent: true))
                .keyboardShortcut(.defaultAction)
            }
        }
        .controlSize(.large)
        .padding(.horizontal, Metrics.onboardingFooterInset)
        .padding(.top, Metrics.accessorySpacing)
        .padding(.bottom, Metrics.windowPadding)
    }
}

private struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: Metrics.inlineSpacing) {
            ForEach(0 ..< count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary))
                    .frame(width: index == current ? 18 : 7, height: 7)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Step \(current + 1) of \(count)")
    }
}

private struct StepTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .opacity(phase.isIdentity ? 1 : 0)
            .offset(y: phase.value * -8)
    }
}
