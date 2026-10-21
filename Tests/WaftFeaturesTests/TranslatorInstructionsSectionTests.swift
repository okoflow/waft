import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct TranslatorInstructionsSectionTests {
    private let state = SettingsWindowState()

    @Test(arguments: TextTask.Kind.allCases)
    func `opens the editor of the instructions with Waft+`(kind: TextTask.Kind) {
        state.selection = .translator
        section(pro: .unlicensed()).edit(kind)

        #expect(state.editedTextTask == kind)
        #expect(state.selection == .translator)
    }

    @Test(.enabled(if: !ProAccess.isFreeDuringBeta))
    func `shows Waft+ instead of the editor without it`() {
        state.selection = .translator
        section(pro: .unlicensed(trialStarted: .distantPast)).edit(.translate)

        #expect(state.editedTextTask == nil)
        #expect(state.selection == .pro)
    }

    private func section(pro: ProModel) -> TranslatorInstructionsSection {
        TranslatorInstructionsSection(settings: .inMemory(), pro: pro, state: state)
    }
}
