import SwiftUI

struct OnboardingStep<Hero: View, Content: View>: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    @ViewBuilder let hero: Hero
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            hero

            Text(title)
                .font(.heroTitle)
                .padding(.top, 20)

            Text(message)
                .font(.rowTitle)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            content
                .padding(.top, 28)
        }
        .frame(maxWidth: 480)
    }
}
