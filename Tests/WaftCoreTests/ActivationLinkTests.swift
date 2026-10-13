import Foundation
import Testing
import WaftCore

struct ActivationLinkTests {
    @Test(arguments: [
        ("waft://activate?key=WFT1.abc.def", String?.some("WFT1.abc.def")),
        ("waft://activate?source=email&key=WFT1.abc.def", "WFT1.abc.def"),
        ("waft://activate?key=a%2Bb%3D", "a+b="),
        ("waft://activate?other=1", nil),
        ("waft://activate", nil),
        ("waft://deactivate?key=WFT1.abc.def", nil),
        ("https://activate?key=WFT1.abc.def", nil),
        ("https://waft.okoflow.com/activate?key=WFT1.abc.def", nil),
    ])
    func `reads the key from an activation link`(link: String, key: String?) throws {
        let url = try #require(URL(string: link))

        #expect(ActivationLink.key(in: url) == key)
    }
}
