import Testing
@testable import WaftFeatures

struct LanguagePickerStateTests {
    @Test(arguments: [true, false])
    func `clears the search and the hovered row when it opens or closes`(isPresented: Bool) {
        let state = LanguagePickerState()
        state.isPresented = !isPresented
        state.query = "French"
        state.hover("fr", true)

        state.isPresented = isPresented

        #expect(state.query.isEmpty)
        #expect(state.hoveredRow == nil)
    }

    @Test
    func `keeps the hovered row when the pointer leaves the row it hovered before`() {
        let state = LanguagePickerState()

        state.hover("fr", true)
        state.hover("de", true)
        state.hover("fr", false)

        #expect(state.hoveredRow == "de")

        state.hover("de", false)

        #expect(state.hoveredRow == nil)
    }
}
