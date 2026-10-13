import SwiftUI
import WaftCore

struct ProSettingsPane: View {
    let pro: ProModel

    var body: some View {
        ProHero(pro: pro)

        SettingsSection("What Pro adds") {
            DividedForEach(ProBenefit.all, id: \.symbolName) { benefit in
                TileRow(symbolName: benefit.symbolName, tint: benefit.tint, title: benefit.title, detail: benefit.detail) {
                    Image(systemName: pro.isUnlocked ? "checkmark.circle.fill" : "lock.fill")
                        .foregroundStyle(pro.isUnlocked ? Palette.success : .secondary)
                        .accessibilityLabel(pro.isUnlocked ? Text("Included") : Text("Locked"))
                }
            }
        }

        if pro.showsLicenseSection {
            LicenseSection(pro: pro)
        }
    }
}

private struct ProHero: View {
    let pro: ProModel

    private var status: String {
        switch pro.access.status {
        case let .licensed(license):
            String(localized: "Licensed to \(license.holder). Thank you!")
        case .beta:
            String(localized: "Free while Waft is in beta.")
        case .trial:
            String(localized: "Free trial ends \(pro.trialEnds.formatted(.relative(presentation: .named)))")
        case .expired:
            String(localized: "Your free trial has ended.")
        }
    }

    private var isForSale: Bool {
        switch pro.access.status {
        case .trial, .expired: true
        case .licensed, .beta: false
        }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)

        HStack(spacing: 16) {
            AppIcon(size: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text("Waft Pro")
                    .font(.system(size: 22, weight: .bold))

                Text(status)
                    .font(.rowTitle)
                    .opacity(0.9)
            }

            Spacer(minLength: 0)

            if isForSale {
                Button("Buy for \(ProModel.price)", action: pro.purchase)
                    .buttonStyle(ProButtonStyle())
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(Palette.proGradient, in: shape)
    }
}

private struct ProBenefit {
    static let all = [
        ProBenefit(
            symbolName: "text.badge.checkmark",
            tint: .purple,
            title: "Clean and Formal",
            detail: "Fillers and false starts go; grammar, punctuation, and tone get fixed.",
        ),
        ProBenefit(
            symbolName: "globe",
            tint: .blue,
            title: "Translate",
            detail: "Speak any of 45 languages and get another, one way or both.",
        ),
        ProBenefit(
            symbolName: "cpu.fill",
            tint: .teal,
            title: "Any AI model",
            detail: "Claude or OpenAI with your own key, or a local model on your Mac.",
        ),
        ProBenefit(
            symbolName: "text.cursor",
            tint: .orange,
            title: "Editing by voice",
            detail: "Select text and say what to change.",
        ),
        ProBenefit(
            symbolName: "waveform",
            tint: .red,
            title: "File transcription",
            detail: "Recordings and videos become text and subtitles.",
        ),
        ProBenefit(
            symbolName: "scope",
            tint: .green,
            title: "Accurate speech model",
            detail: "Whisper large-v3 makes fewer mistakes outside English.",
        ),
        ProBenefit(
            symbolName: "slider.horizontal.3",
            tint: .gray,
            title: "Your own instructions",
            detail: "Tune Clean, Formal, and Translate to the way you write.",
        ),
    ]

    let symbolName: String
    let tint: TileTint
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
}
