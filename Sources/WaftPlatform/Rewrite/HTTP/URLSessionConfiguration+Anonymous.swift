import Foundation

extension URLSessionConfiguration {
    static var anonymous: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpAdditionalHeaders = ["User-Agent": "Waft", "Accept-Language": "en"]

        return configuration
    }
}
