package import Foundation

extension LocalServer {
    package func url(appending path: String) throws(RewriteError) -> URL {
        var base = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)

        while base.hasSuffix("/") {
            base.removeLast()
        }

        guard let url = URL(string: base + path), url.host() != nil else { throw .unavailable }

        return url
    }
}
