@MainActor
package protocol KeyboardLayout: AnyObject {
    func character(forKeyCode keyCode: Int64) -> String?
}
