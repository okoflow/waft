import AppKit
import SwiftUI

enum Palette {
    static let windowColor = hex(light: 0xFFFFFF, dark: 0x1C1C1E)
    static let window = Color(nsColor: windowColor)
    static let sidebar = Color(nsColor: hex(light: 0xECECEE, dark: 0x232326))
    static let sidebarBorder = Color(nsColor: dynamic(light: (0, 0.07), dark: (1, 0.08)))
    static let selection = Color(nsColor: dynamic(light: (0, 0.07), dark: (1, 0.1)))
    static let hover = Color(nsColor: dynamic(light: (0, 0.035), dark: (1, 0.05)))
    static let card = Color(nsColor: hex(light: 0xF5F5F7, dark: 0x2A2A2D))
    static let cardBorder = Color(nsColor: dynamic(light: (0, 0.04), dark: (1, 0.05)))
    static let control = Color(nsColor: dynamic(light: (0, 0.08), dark: (1, 0.12)))
    static let controlPressed = Color(nsColor: dynamic(light: (0, 0.14), dark: (1, 0.2)))
    static let field = Color(nsColor: hex(light: 0xFFFFFF, dark: 0x3A3A3D))
    static let fieldBorder = Color(nsColor: dynamic(light: (0, 0.12), dark: (1, 0.14)))
    static let dropZoneBorder = Color(nsColor: dynamic(light: (0, 0.18), dark: (1, 0.2)))
    static let separator = Color(nsColor: .separatorColor)
    static let success = Color.green
    static let warning = Color.orange
    static let danger = Color.red
    static let accent = Color(nsColor: hex(light: 0x7C3AED, dark: 0x8B5CF6))
    static let plusTint = Color(nsColor: hex(light: 0xF1EDFD, dark: 0x241F38))
    static let pressedOpacity = 0.82

    private nonisolated static func hex(light: UInt32, dark: UInt32) -> NSColor {
        NSColor(name: nil) { appearance in
            let value = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light

            return NSColor(
                srgbRed: CGFloat(value >> 16 & 0xFF) / 255,
                green: CGFloat(value >> 8 & 0xFF) / 255,
                blue: CGFloat(value & 0xFF) / 255,
                alpha: 1,
            )
        }
    }

    private nonisolated static func dynamic(light: (CGFloat, CGFloat), dark: (CGFloat, CGFloat)) -> NSColor {
        NSColor(name: nil) { appearance in
            let (white, alpha) = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light

            return NSColor(white: white, alpha: alpha)
        }
    }
}
