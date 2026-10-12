package import Foundation

@MainActor
package protocol URLOpener: AnyObject {
    func open(_ url: URL)
    func reveal(_ url: URL)
}
