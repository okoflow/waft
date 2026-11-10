import Carbon.HIToolbox
import CoreGraphics
import WaftCore

enum SecureInput {
    private static let holderKey = "kCGSSessionSecureInputPID"

    static var holder: SecureInputHolder {
        guard IsSecureEventInputEnabled() else { return .nobody }
        guard let session = CGSessionCopyCurrentDictionary() as? [String: Any],
              let processID = session[holderKey] as? NSNumber
        else { return .unknown }

        return .process(processID.int32Value)
    }
}
