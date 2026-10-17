import Testing
import WaftCore
@testable import WaftFeatures

struct OnboardingModelTests {
    enum Navigation: CaseIterable {
        case back
        case reset
        case resume
        case advance
        case finish
    }

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

    @Test(arguments: [(Permission.microphone, false), (.microphone, true), (.accessibility, false), (.accessibility, true)])
    func `stays on a permission revoked during the success pause`(permission: Permission, refreshesMonitor: Bool) async throws {
        let setup = OnboardingSetup(permission)
        await setup.model.proceed()
        let advance = try await setup.grant(permission)

        setup.setStatus(.denied, for: permission, refreshesMonitor: refreshesMonitor)
        setup.pause.release()
        await advance.value

        #expect(setup.model.step.permission == permission)
        #expect(setup.model.pendingStatus == .denied)
    }

    @Test(arguments: Navigation.allCases)
    func `invalidates a delayed advance before navigation and reentry`(navigation: Navigation) async throws {
        let setup = OnboardingSetup(.microphone)
        var finishCount = 0
        setup.model.onFinish = { finishCount += 1 }
        await setup.model.proceed()
        let advance = try await setup.grant(.microphone)

        await navigate(navigation, in: setup.model)

        #expect(advance.isCancelled)

        setup.setStatus(.denied, for: .microphone)
        setup.model.reset()
        await setup.model.proceed()
        setup.setStatus(.granted, for: .microphone)
        setup.pause.release()
        await advance.value

        #expect(setup.model.step == .microphone)
        #expect(finishCount == (navigation == .finish ? 1 : 0))
    }

    @Test(arguments: [false, true])
    func `advances only for the latest permission notification`(refreshesPermissions: Bool) async throws {
        let setup = OnboardingSetup(.microphone)
        await setup.model.proceed()
        let previous = try await setup.grant(.microphone)

        if refreshesPermissions {
            setup.permissions.onChange = { [weak model = setup.model] in model?.permissionsDidChange() }
            setup.setStatus(.denied, for: .accessibility, refreshesMonitor: false)
        } else {
            setup.model.permissionsDidChange()
        }

        setup.pause.release()
        await previous.value
        let current = try #require(setup.model.advanceTask)
        await setup.pause.waitUntilPaused()

        #expect(previous.isCancelled)
        #expect(setup.model.step == .microphone)

        setup.pause.release()
        await current.value

        #expect(setup.model.step == (refreshesPermissions ? .accessibility : .practice))
        #expect(!current.isCancelled)
    }

    @Test
    func `finishes only once when a granted permission still has a delayed advance`() async throws {
        let setup = OnboardingSetup(.microphone)
        var finishCount = 0
        setup.model.onFinish = { finishCount += 1 }
        setup.model.resume()
        let advance = try await setup.grant(.microphone)

        setup.model.finish()
        setup.pause.release()
        await advance.value

        #expect(finishCount == 1)
    }

    private func model(_ permissions: FakePermissionProvider) -> OnboardingModel {
        OnboardingModel(permissions: PermissionMonitor(provider: permissions), grantedPause: .zero)
    }

    private func navigate(_ navigation: Navigation, in model: OnboardingModel) async {
        switch navigation {
        case .back: model.goBack()
        case .reset: model.reset()
        case .resume: model.resume()
        case .advance: await model.proceed()
        case .finish: model.finish()
        }
    }
}

private struct OnboardingSetup {
    let model: OnboardingModel
    let pause: FakePause
    let permissions: PermissionMonitor

    private let provider: FakePermissionProvider

    init(_ permission: Permission) {
        let provider = FakePermissionProvider([.microphone: .granted, .accessibility: .granted])
        provider.setStatus(.denied, for: permission)
        let permissions = PermissionMonitor(provider: provider)
        let pause = FakePause()

        self.provider = provider
        self.permissions = permissions
        self.pause = pause
        model = OnboardingModel(permissions: permissions, grantedPause: .zero, waitForPause: pause.wait)
    }

    func setStatus(_ status: PermissionStatus, for permission: Permission, refreshesMonitor: Bool = true) {
        provider.setStatus(status, for: permission)

        guard refreshesMonitor else { return }

        permissions.refresh()
    }

    func grant(_ permission: Permission) async throws -> Task<Void, Never> {
        setStatus(.granted, for: permission)
        model.permissionsDidChange()
        let advance = try #require(model.advanceTask)
        await pause.waitUntilPaused()

        return advance
    }
}

private final class FakePause {
    private let pauses: AsyncStream<Void>
    private let pauseContinuation: AsyncStream<Void>.Continuation
    private var pending: [CheckedContinuation<Bool, Never>] = []

    init() {
        (pauses, pauseContinuation) = AsyncStream.makeStream(of: Void.self)
    }

    func wait(for _: Duration) async -> Bool {
        await withCheckedContinuation { continuation in
            pending.append(continuation)
            pauseContinuation.yield(())
        }
    }

    func waitUntilPaused() async {
        var iterator = pauses.makeAsyncIterator()
        _ = await iterator.next()
    }

    func release() {
        guard !pending.isEmpty else { return }

        pending.removeFirst().resume(returning: true)
    }
}
