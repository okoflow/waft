package import Foundation

package enum ActivationLink {
    package static func key(in url: URL) -> String? {
        guard url.scheme == "waft", url.host() == "activate",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return nil }

        return components.queryItems?.first { $0.name == "key" }?.value
    }
}
