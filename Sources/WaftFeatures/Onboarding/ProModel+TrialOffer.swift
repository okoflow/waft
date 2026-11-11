import SwiftUI
import WaftCore

extension ProModel {
    var trialOffer: LocalizedStringKey? {
        guard access.status == .trial else { return nil }

        let days = ProAccess.trialDays
        let price = Self.price

        return "Dictation is free forever. The AI features are part of Waft+: free for \(days) days, then \(price) once."
    }
}
