import Foundation

struct APICall<Body: Encodable> {
    let url: URL
    let headers: [String: String]
    let body: Body
}
