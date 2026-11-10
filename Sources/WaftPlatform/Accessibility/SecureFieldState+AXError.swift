import ApplicationServices
import WaftCore

extension SecureFieldState {
    init(subrole: String?, status: AXError) {
        switch status {
        case .success: self = subrole == kAXSecureTextFieldSubrole ? .secure : .notSecure
        case .attributeUnsupported, .noValue: self = .notSecure
        default: self = .unreadable
        }
    }
}
