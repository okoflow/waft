import Testing
import WaftCore
@testable import WaftFeatures

struct SettingsWindowStateTests {
    @Test(arguments: [
        (SettingsPane.dictation, 1, SettingsPane.dictionary),
        (.overview, -1, .overview),
        (.about, 1, .about),
        (.overview, 3, .writing),
    ])
    func `moves the selection by an offset within the panes`(selected: SettingsPane, offset: Int, moved: SettingsPane) {
        let state = SettingsWindowState()
        state.selection = selected
        state.move(by: offset)

        #expect(state.selection == moved)
    }

    @Test
    func `closes the editors when the selection changes`() {
        let state = SettingsWindowState()
        state.editedMode = .clean
        state.editedTextTask = .fix
        state.selection = .writing

        #expect(state.editedMode == nil)
        #expect(state.editedTextTask == nil)
    }

    @Test
    func `clears the hover only for the pane that is hovered`() {
        let state = SettingsWindowState()
        state.hover(.general, true)
        state.hover(.dictation, false)

        #expect(state.hoveredPane == .general)

        state.hover(.general, false)

        #expect(state.hoveredPane == nil)
    }
}
