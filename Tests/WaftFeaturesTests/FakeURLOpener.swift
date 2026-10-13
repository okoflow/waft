import Foundation
import WaftCore

final class FakeURLOpener: URLOpener {
    private(set) var opened: [URL] = []

    func open(_ url: URL) {
        opened.append(url)
    }

    func reveal(_: URL) {}
}
