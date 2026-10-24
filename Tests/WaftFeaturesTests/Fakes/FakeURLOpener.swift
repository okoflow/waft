import Foundation
import WaftCore

final class FakeURLOpener: URLOpener {
    private(set) var opened: [URL] = []
    private(set) var revealed: [URL] = []

    func open(_ url: URL) {
        opened.append(url)
    }

    func reveal(_ url: URL) {
        revealed.append(url)
    }
}
