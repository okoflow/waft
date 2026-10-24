import SwiftUI

extension View {
    func windowChrome() -> some View {
        buttonStyle(PushButtonStyle())
            .background(Palette.window)
            .ignoresSafeArea()
    }
}
