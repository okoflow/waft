import Foundation
import os
import WaftCore

enum APIKey {
    static func load(from store: any ValueStore<String>) throws(RewriteError) -> String {
        let key: String?

        do {
            key = try store.load()
        } catch {
            Logger.network.error("Couldn't read the API key", cause: error)

            throw .missingKey
        }

        guard let key, !key.isEmpty else { throw .missingKey }

        return key
    }
}
