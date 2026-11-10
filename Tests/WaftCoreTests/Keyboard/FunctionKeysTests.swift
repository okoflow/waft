import Testing
@testable import WaftCore

struct FunctionKeysTests {
    @Test(arguments: [(122, "F1"), (105, "F13"), (90, "F20"), (53, nil), (0, nil)] as [(Int64, String?)])
    func `titles a function key by its number and no other key`(keyCode: Int64, title: String?) {
        #expect(FunctionKeys.title(forKeyCode: keyCode) == title)
    }
}
