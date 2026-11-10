import Testing
import WaftCore
@testable import WaftFeatures

struct OnboardingModelStepsTests {
    @Test(arguments: [
        (
            [Permission: PermissionStatus](),
            false,
            [.welcome, .microphone, .accessibility, .practice, .done] as [OnboardingModel.Step],
        ),
        ([.microphone: .granted, .accessibility: .granted], false, [.welcome, .practice, .done]),
        ([.accessibility: .granted], true, [.microphone]),
    ])
    func `lists the steps it shows`(statuses: [Permission: PermissionStatus], resumes: Bool, steps: [OnboardingModel.Step]) {
        let onboarding = model(FakePermissionProvider(statuses))

        if resumes {
            onboarding.resume()
        }

        #expect(onboarding.steps == steps)
    }

    @Test
    func `keeps listing a permission step it showed once the permission is granted`() async {
        let onboarding = model(FakePermissionProvider([.accessibility: .granted], answers: [.microphone: .granted]))

        await onboarding.proceed()
        await onboarding.proceed()

        #expect(onboarding.pendingStatus == nil)
        #expect(onboarding.steps == [.welcome, .microphone, .practice, .done])
    }

    @Test
    func `lists the steps from the welcome step again after it starts over`() async {
        let onboarding = model(FakePermissionProvider([.accessibility: .granted], answers: [.microphone: .granted]))

        await onboarding.proceed()
        await onboarding.proceed()
        onboarding.reset()

        #expect(onboarding.steps == [.welcome, .practice, .done])
    }

    private func model(_ permissions: FakePermissionProvider) -> OnboardingModel {
        OnboardingModel(permissions: PermissionMonitor(provider: permissions), settings: .inMemory(usageSharing: .declined))
    }
}
