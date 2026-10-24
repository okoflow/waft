import AppKit
import SwiftUI

struct FileIcon: View {
    private static let size: CGFloat = 32

    let url: URL

    var body: some View {
        Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
            .resizable()
            .frame(width: Self.size, height: Self.size)
            .accessibilityHidden(true)
    }
}
