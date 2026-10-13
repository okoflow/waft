import Testing
@testable import WaftCore

struct LicenseTests {
    @Test(arguments: [("Ann", "Ann"), (nil, "ann@example.com"), ("", "ann@example.com")])
    func `names the license holder`(name: String?, holder: String) {
        #expect(License(email: "ann@example.com", name: name).holder == holder)
    }
}
