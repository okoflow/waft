import SwiftUI
import Testing
import WaftCore
@testable import WaftFeatures

struct ModeEditorPageTests {
    private let settings = SettingsModel.inMemory()
    private let custom = CustomMode(name: "Original name", instructions: "Original instructions")

    @Test
    func `preserves independent edits through retained custom mode bindings`() throws {
        let page = page()
        let name = page.binding(\.name, of: custom)
        let instructions = page.binding(\.instructions, of: custom)

        name.wrappedValue = "Updated name"
        instructions.wrappedValue = "Updated instructions"

        let current = try #require(settings.settings.customMode(custom.id))

        #expect(current.name == "Updated name")
        #expect(current.instructions == "Updated instructions")
        #expect(name.wrappedValue == current.name)
        #expect(instructions.wrappedValue == current.instructions)
    }

    @Test
    func `reads later settings changes through retained custom mode bindings`() {
        let page = page()
        let name = page.binding(\.name, of: custom)
        let instructions = page.binding(\.instructions, of: custom)
        var updated = custom
        updated.name = "Changed elsewhere"
        updated.instructions = "Changed instructions"

        settings.settings.update(updated)

        #expect(name.wrappedValue == updated.name)
        #expect(instructions.wrappedValue == updated.instructions)
    }

    @Test
    func `ignores retained binding writes after the custom mode is removed`() {
        let page = page()
        let name = page.binding(\.name, of: custom)
        let instructions = page.binding(\.instructions, of: custom)
        let other = CustomMode(name: "Other mode", instructions: "Keep these instructions")
        settings.settings.customModes.append(other)
        settings.settings.removeCustomMode(custom.id)

        #expect(name.wrappedValue.isEmpty)
        #expect(instructions.wrappedValue.isEmpty)

        name.wrappedValue = "Deleted name"
        instructions.wrappedValue = "Deleted instructions"

        #expect(settings.settings.customModes == [other])
    }

    private func page() -> ModeEditorPage {
        settings.settings.customModes = [custom]

        return ModeEditorPage(
            mode: .custom(custom.id),
            settings: settings,
            tryout: ModeTryoutModel(rewriters: .all(FakeTextRewriter()), settings: settings, pro: .unlicensed()),
            state: SettingsWindowState(),
        )
    }
}
