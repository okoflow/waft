import SwiftUI
import WaftCore

struct ProSettingsPane: View {
    let pro: ProModel

    var body: some View {
        ProHero(pro: pro)

        SettingsSection("What Waft+ adds") {
            DividedForEach(ProBenefit.all, id: \.symbolName) { benefit in
                TileRow(symbolName: benefit.symbolName, tint: benefit.tint, title: benefit.title, detail: benefit.detail) {
                    Image(systemName: pro.isUnlocked ? "checkmark.circle.fill" : "lock.fill")
                        .foregroundStyle(pro.isUnlocked ? Palette.accent : Palette.secondaryText)
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
    private static let iconSize: CGFloat = 64
    private static let padding: CGFloat = 20

    let pro: ProModel

    private var status: String {
        switch pro.access.status {
        case let .licensed(license):
            String(localized: "Licensed to \(license.holder). Thank you!")
        case .beta:
            String(localized: "Free while Waft is in beta.")
        case .trial:
            String(localized: "Free trial ends \(pro.trialEnds.formatted(.relative(presentation: .named))).")
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
        let shape = RoundedRectangle.card

        HStack(spacing: Metrics.rowSpacing) {
            AppIcon(size: Self.iconSize)

            VStack(alignment: .leading, spacing: Metrics.heroSpacing) {
                HStack(spacing: Metrics.inlineSpacing) {
                    Text(verbatim: "Waft")
                        .font(.proTitle)

                    WaftPlusMark(size: 26)
                }
                .environment(\.layoutDirection, .leftToRight)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Waft+"))
                .accessibilityAddTraits(.isHeader)

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
        .padding(Self.padding)
        .brandGlow(in: shape)
    }
}

private struct ProBenefit {
    static let all = [
        ProBenefit(
            symbolName: "text.badge.checkmark",
            tint: .indigo,
            title: "Clean and Formal",
            detail: "Removes fillers and false starts, and fixes grammar and tone.",
        ),
        ProBenefit(
            symbolName: SettingsPane.writing.symbolName,
            tint: SettingsPane.writing.tint,
            title: "Your own modes",
            detail: "Make modes with your own instructions, or tune the built-in ones.",
        ),
        ProBenefit(
            symbolName: "globe",
            tint: .blue,
            title: "Translate",
            detail: "Speak any of \(Language.allCases.count) languages and get another, one way or both.",
        ),
        ProBenefit(
            symbolName: SettingsPane.translator.symbolName,
            tint: SettingsPane.translator.tint,
            title: "Translator",
            detail: "Translates in its own window, and translates or fixes selected text in any app.",
        ),
        ProBenefit(
            symbolName: SettingsPane.aiModels.symbolName,
            tint: SettingsPane.aiModels.tint,
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
            detail: "Recognizes speech more accurately, especially outside English.",
        ),
    ]

    let symbolName: String
    let tint: TileTint
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
}
