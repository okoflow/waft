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
                .accessibilityAddTraits(.isHeader)
                .padding(.top, Metrics.windowSpacing)

            Text(message)
                .font(.rowTitle)
                .foregroundStyle(Palette.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Metrics.controlSpacing)

            content
                .padding(.top, Metrics.onboardingSectionSpacing)
        }
        .frame(maxWidth: Metrics.onboardingContentWidth)
    }
}
