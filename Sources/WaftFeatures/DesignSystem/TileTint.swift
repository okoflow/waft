import SwiftUI

enum TileTint {
    case gray
    case red
    case purple
    case orange
    case blue
    case green
    case indigo
    case teal

    var gradient: LinearGradient {
        LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
    }

    private var top: Color {
        switch self {
        case .gray: Color(hex: 0xA2A2AA)
        case .red: Color(hex: 0xF4646B)
        case .purple: Color(hex: 0xA37BEF)
        case .orange: Color(hex: 0xF6A54A)
        case .blue: Color(hex: 0x4B98F8)
        case .green: Color(hex: 0x3EC77F)
        case .indigo: Color(hex: 0x7878F2)
        case .teal: Color(hex: 0x3CC0D2)
        }
    }

    private var bottom: Color {
        switch self {
        case .gray: Color(hex: 0x8A8A93)
        case .red: Color(hex: 0xE8515A)
        case .purple: Color(hex: 0x9068E4)
        case .orange: Color(hex: 0xEF9236)
        case .blue: Color(hex: 0x3A85EE)
        case .green: Color(hex: 0x2FB36D)
        case .indigo: Color(hex: 0x6565E6)
        case .teal: Color(hex: 0x2BA9BD)
        }
    }
}
