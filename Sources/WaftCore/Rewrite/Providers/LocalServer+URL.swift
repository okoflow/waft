package import Foundation

extension LocalServer {
    package func url(appending path: String) throws(RewriteError) -> URL {
        var base = address

        while base.hasSuffix("/") {
            base.removeLast()
        }

        guard let url = URL(string: base + path),
              let scheme = url.scheme,
              Self.schemes.contains(scheme.lowercased()),
              let host = url.host(),
              !host.isEmpty
        else { throw .unavailable }

        return url
    }
}
