@MainActor
package protocol GlobalShortcut: AnyObject {
    func register(_ combination: KeyCombination, action: @escaping @MainActor () -> Void) -> Bool
    func unregister()
}
