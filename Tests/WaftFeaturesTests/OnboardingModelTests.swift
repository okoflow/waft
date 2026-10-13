import Testing
import WaftCore
@testable import WaftFeatures

struct OnboardingModelTests {
    @Test
    func `skips the permission steps that are already granted`() async {
        let onboarding = model(FakePermissionProvider([.microphone: .granted, .accessibility: .granted]))
        await onboarding.proceed()

        #expect(onboarding.step == .practice)

        onboarding.goBack()

        #expect(onboarding.step == .welcome)
        #expect(!onboarding.canGoBack)
    }

    @Test
    func `asks for a missing permission`() async {
        let permissions = FakePermissionProvider([.accessibility: .granted])
        let onboarding = model(permissions)
        await onboarding.proceed()

        #expect(onboarding.step == .microphone)
        #expect(onboarding.pendingStatus == .notDetermined)

        await onboarding.proceed()

        #expect(permissions.requests == [.microphone])
    }

    @Test
    func `stays on a denied microphone and asks again`() async {
        let permissions = FakePermissionProvider([.accessibility: .granted], answers: [.microphone: .denied])
        let onboarding = model(permissions)
        await onboarding.proceed()
        await onboarding.proceed()
        onboarding.permissionsDidChange()

        #expect(onboarding.step == .microphone)
        #expect(onboarding.pendingStatus == .denied)

        await onboarding.proceed()

        #expect(permissions.requests == [.microphone, .microphone])
    }

    @Test(arguments: [
        ([Permission.microphone: PermissionStatus.notDetermined], Permission.microphone, OnboardingModel.Step.accessibility),
        ([.microphone: .granted, .accessibility: .denied], .accessibility, .practice),
    ])
    func `moves on once the permission is granted`(
        statuses: [Permission: PermissionStatus],
        permission: Permission,
        next: OnboardingModel.Step,
    ) async {
        let onboarding = model(FakePermissionProvider(statuses, answers: [permission: .granted]))
        await onboarding.proceed()
        await onboarding.proceed()

        #expect(onboarding.step.permission == permission)

        onboarding.permissionsDidChange()

        #expect(await Poll.until(timeout: .seconds(5)) { onboarding.step == next })
    }

    @Test
    func `finishes on the done step`() async {
        var finishCount = 0
        let onboarding = model(FakePermissionProvider([.microphone: .granted, .accessibility: .granted]))
        onboarding.onFinish = { finishCount += 1 }

        for _ in 1 ... 3 {
            await onboarding.proceed()
        }

        #expect(onboarding.step == .done)
        #expect(finishCount == 1)
    }

    @Test
    func `resumes on the missing permission and finishes once it is granted`() async {
        var finishCount = 0
        let onboarding = model(FakePermissionProvider([.accessibility: .granted], answers: [.microphone: .granted]))
        onboarding.onFinish = { finishCount += 1 }
        onboarding.resume()

        #expect(onboarding.step == .microphone)
        #expect(!onboarding.canGoBack)

        await onboarding.proceed()
        onboarding.permissionsDidChange()

        #expect(await Poll.until(timeout: .seconds(5)) { finishCount == 1 })
    }

    @Test
    func `starts over from the welcome step`() async {
        let onboarding = model(FakePermissionProvider([.microphone: .granted, .accessibility: .granted]))
        await onboarding.proceed()
        onboarding.practiceText = "Hello."
        onboarding.reset()

        #expect(onboarding.step == .welcome)
        #expect(onboarding.practiceText.isEmpty)
    }

    private func model(_ permissions: FakePermissionProvider) -> OnboardingModel {
        OnboardingModel(permissions: PermissionMonitor(provider: permissions), grantedPause: .zero)
    }
}
