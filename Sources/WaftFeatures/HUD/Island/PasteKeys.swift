import SwiftUI

struct PasteKeys: View {
    private static let keys = ["⌘", "V"]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Self.keys, id: \.self) { key in
                Text(verbatim: key)
                    .font(.hudCaption)
                    .frame(minWidth: 18, minHeight: 18)
                    .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Copied: press \(Self.keys.joined()) to paste"))
    }
}
