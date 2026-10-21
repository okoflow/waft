@testable import WaftFeatures

extension GlobalShortcuts {
    static func fake(
        translator: FakeGlobalShortcut = FakeGlobalShortcut(),
        translateSelection: FakeGlobalShortcut = FakeGlobalShortcut(),
        fixSelection: FakeGlobalShortcut = FakeGlobalShortcut(),
    ) -> GlobalShortcuts {
        GlobalShortcuts(
            modeCycle: FakeGlobalShortcut(),
            translator: translator,
            translateSelection: translateSelection,
            fixSelection: fixSelection,
        )
    }
}
