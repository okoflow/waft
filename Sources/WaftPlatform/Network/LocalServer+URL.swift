import Foundation
import WaftCore

extension LocalServer {
    func url(appending path: String) throws(RewriteError) -> URL {
        var base = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)

        while base.hasSuffix("/") {
            base.removeLast()
        }

        guard let url = URL(string: base + path) else { throw .unavailable }

        return url
    }
}
