@MainActor
package protocol OutputVolume: AnyObject {
    func lower(to fraction: Float)

    func restore()
}
