import ApplicationServices
import Testing
import WaftCore
@testable import WaftPlatform

struct SecureFieldStateAXErrorTests {
    @Test(arguments: [
        (String?.some(kAXSecureTextFieldSubrole), SecureFieldState.secure),
        (kAXSearchFieldSubrole, .notSecure),
        (nil, .notSecure),
    ])
    func `takes the subrole it could read as the answer`(subrole: String?, expected: SecureFieldState) {
        #expect(SecureFieldState(subrole: subrole, status: .success) == expected)
    }

    @Test(arguments: [AXError.attributeUnsupported, .noValue])
    func `takes a field without a subrole as not secure`(status: AXError) {
        #expect(SecureFieldState(subrole: nil, status: status) == .notSecure)
    }

    @Test(arguments: [AXError.failure, .illegalArgument, .invalidUIElement, .cannotComplete, .notImplemented, .apiDisabled])
    func `takes a field that did not answer as unreadable`(status: AXError) {
        #expect(SecureFieldState(subrole: nil, status: status) == .unreadable)
    }
}
