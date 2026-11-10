import Testing
import WaftCore
@testable import WaftFeatures

struct OnboardingModelUsageTests {
    private let settings = SettingsModel.inMemory()

    @Test(arguments: [(true, UsageSharing.allowed), (false, .declined)])
    func `asks about usage data before the last step and keeps the answer`(shares: Bool, sharing: UsageSharing) async {
        let onboarding = model()

        await onboarding.proceed()
        await onboarding.proceed()

        #expect(onboarding.step == .usage)
        #expect(settings.settings.usageSharing == .undecided)

        onboarding.answerUsage(shares: shares)

        #expect(onboarding.step == .done)
        #expect(settings.settings.usageSharing == sharing)
    }

    @Test
    func `goes back to the question so the answer can change`() async {
        let onboarding = model()

        await onboarding.proceed()
        await onboarding.proceed()
        onboarding.answerUsage(shares: true)
        onboarding.goBack()

        #expect(onboarding.step == .usage)

        onboarding.answerUsage(shares: false)

        #expect(settings.settings.usageSharing == .declined)
    }

    @Test
    func `asks only about usage data after a finished setup and finishes with the answer`() {
        var finishCount = 0
        let onboarding = model()
        onboarding.onFinish = { finishCount += 1 }

        onboarding.resume()

        #expect(onboarding.steps == [.usage])
        #expect(onboarding.step == .usage)

        onboarding.answerUsage(shares: false)

        #expect(finishCount == 1)
    }

    private func model() -> OnboardingModel {
        let permissions = FakePermissionProvider([.microphone: .granted, .accessibility: .granted])

        return OnboardingModel(permissions: PermissionMonitor(provider: permissions), settings: settings)
    }
}
