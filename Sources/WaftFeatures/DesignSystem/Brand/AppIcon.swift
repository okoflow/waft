import AppKit
import SwiftUI

struct AppIcon: View {
    private static let artwork = loadArtwork()

    let size: CGFloat

    var body: some View {
        Image(nsImage: Self.artwork)
            .resizable()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private static func loadArtwork() -> NSImage {
        guard let url = Bundle.main.url(forResource: "Waft", withExtension: "icns"), let image = NSImage(contentsOf: url) else {
            return NSApp.applicationIconImage
        }

        return image
    }
}
