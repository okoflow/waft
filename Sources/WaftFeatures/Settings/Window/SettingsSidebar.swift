import SwiftUI

struct SettingsSidebar: View {
    fileprivate static let rowInset: CGFloat = 6

    private static let rowSpacing: CGFloat = 4
    private static let groupSpacing: CGFloat = 12
    private static let top: CGFloat = 48
    private static let radius: CGFloat = 18

    let state: SettingsWindowState

    var body: some View {
        VStack(alignment: .leading, spacing: Self.rowSpacing) {
            ForEach(SidebarGroup.all, id: \.panes) { group in
                if let title = group.title {
                    Text(title)
                        .font(.sidebarGroup)
                        .foregroundStyle(Palette.secondaryText)
                        .padding(.leading, Self.rowInset)
                        .padding(.top, Self.groupSpacing)
                        .accessibilityAddTraits(.isHeader)
                }

                ForEach(group.panes, id: \.self) { pane in
                    SidebarRow(pane: pane, state: state)
                }
            }

            Spacer(minLength: 0)

            SidebarRow(pane: .pro, state: state)
            SidebarRow(pane: .about, state: state)
        }
        .padding(.horizontal, Metrics.rowPadding)
        .padding(.top, Self.top)
        .padding(.bottom, Metrics.rowPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            let shape = RoundedRectangle(cornerRadius: Self.radius, style: .continuous)

            shape
                .fill(Palette.sidebar)
                .overlay {
                    shape.stroke(Palette.sidebarBorder, lineWidth: 1)
                }
        }
        .focusable()
        .focusEffectDisabled()
        .onMoveCommand { direction in
            switch direction {
            case .up: state.move(by: -1)
            case .down: state.move(by: 1)
            default: break
            }
        }
    }
}

private struct SidebarRow: View {
    private static let radius: CGFloat = 9
    private static let height: CGFloat = 36

    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    let pane: SettingsPane
    let state: SettingsWindowState

    private var isSelected: Bool {
        state.selection == pane
    }

    private var showsHover: Bool {
        guard !isSelected else { return false }

        return state.hoveredPane == pane
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Self.radius, style: .continuous)

        Button {
            state.selection = pane
        } label: {
            HStack(spacing: Metrics.iconLabelSpacing) {
                if pane == .pro {
                    WaftPlusMark(size: Metrics.tileSize)
                } else {
                    IconTile(symbolName: pane.symbolName, tint: pane.tint)
                }

                Text(pane.title)
                    .font(.rowTitle)

                Spacer(minLength: 0)

                if pane.needsWaftPlus {
                    ProBadge()
                }
            }
            .padding(.horizontal, SettingsSidebar.rowInset)
            .frame(height: Self.height)
            .background {
                ZStack {
                    shape
                        .fill(Palette.hover)
                        .animation(Motion.adapted(Motion.fade, reducesMotion: reducesMotion)) { fill in
                            fill.opacity(showsHover ? 1 : 0)
                        }

                    if isSelected {
                        shape.fill(Palette.selection)
                    }
                }
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .onHover { state.hover(pane, $0) }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
