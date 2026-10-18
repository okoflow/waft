import SwiftUI

struct SettingsSidebar: View {
    let state: SettingsWindowState

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.sidebarRowSpacing) {
            ForEach(Array(SidebarGroup.all.enumerated()), id: \.offset) { index, group in
                if let title = group.title {
                    Text(title)
                        .font(.sidebarGroup)
                        .foregroundStyle(.secondary)
                        .padding(.leading, Metrics.sidebarRowInset)
                        .padding(.top, index == 0 ? 0 : Metrics.sidebarGroupSpacing)
                        .accessibilityAddTraits(.isHeader)
                } else if index > 0 {
                    Spacer()
                        .frame(height: Metrics.sidebarGroupSpacing)
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
        .padding(.top, Metrics.sidebarTop)
        .padding(.bottom, Metrics.rowPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            SidebarBackground()
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

private struct SidebarBackground: View {
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Metrics.sidebarRadius, style: .continuous)

        shape
            .fill(Palette.sidebar)
            .overlay {
                shape.stroke(Palette.sidebarBorder, lineWidth: 1)
            }
    }
}

private struct SidebarRow: View {
    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    let pane: SettingsPane
    let state: SettingsWindowState

    private var isSelected: Bool {
        state.selection == pane
    }

    private var showsHover: Bool {
        state.hoveredPane == pane && !isSelected
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Metrics.rowRadius, style: .continuous)

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
            .padding(.horizontal, Metrics.sidebarRowInset)
            .frame(height: Metrics.sidebarRowHeight)
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
