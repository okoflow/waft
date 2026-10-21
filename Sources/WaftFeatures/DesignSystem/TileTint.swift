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
        let (top, bottom): (UInt32, UInt32) =
            switch self {
            case .gray: (0xA2A2AA, 0x8A8A93)
            case .red: (0xF4646B, 0xE8515A)
            case .purple: (0xA37BEF, 0x9068E4)
            case .orange: (0xF6A54A, 0xEF9236)
            case .blue: (0x4B98F8, 0x3A85EE)
            case .green: (0x3EC77F, 0x2FB36D)
            case .indigo: (0x7878F2, 0x6565E6)
            case .teal: (0x3CC0D2, 0x2BA9BD)
            }

        return LinearGradient(colors: [Color(hex: top), Color(hex: bottom)], startPoint: .top, endPoint: .bottom)
    }
}
