import SwiftUI

struct SettingsPage<Content: View, Accessory: View>: View {
    private let title: LocalizedStringKey
    private let back: (() -> Void)?
    private let accessory: Accessory
    private let content: Content

    init(
        _ title: LocalizedStringKey,
        back: @escaping () -> Void,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder content: () -> Content,
    ) {
        self.title = title
        self.back = back
        self.accessory = accessory()
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.sectionSpacing) {
                    content
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Metrics.pagePadding)
                .padding(.top, Metrics.pageTop)
                .padding(.bottom, Metrics.pagePadding)
            }
            .hidingSystemScrollEdge()

            header
        }
    }

    private var header: some View {
        HStack(spacing: Metrics.controlSpacing) {
            if let back {
                Button(action: back) {
                    Image(systemName: "chevron.left")
                        .font(.glyph)
                        .frame(width: Metrics.controlHeight, height: Metrics.controlHeight)
                        .background(Palette.control, in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Back")
                .accessibilityLabel(Text("Back"))
            }

            Text(title)
                .font(.pageTitle)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)

            accessory
        }
        .frame(maxWidth: .infinity, minHeight: Metrics.titleBarHeight, maxHeight: Metrics.titleBarHeight)
        .padding(.horizontal, Metrics.pagePadding)
        .background(alignment: .top) {
            LinearGradient(
                stops: [
                    .init(color: Palette.window, location: 0),
                    .init(color: Palette.window, location: 0.76),
                    .init(color: Palette.window.opacity(0), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom,
            )
            .frame(height: Metrics.pageTop - 5)
            .allowsHitTesting(false)
        }
    }
}

extension SettingsPage where Accessory == EmptyView {
    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        back = nil
        accessory = EmptyView()
        self.content = content()
    }
}

extension View {
    @ViewBuilder
    fileprivate func hidingSystemScrollEdge() -> some View {
        if #available(macOS 26, *) {
            scrollEdgeEffectHidden(true, for: .top)
        } else {
            self
        }
    }
}
