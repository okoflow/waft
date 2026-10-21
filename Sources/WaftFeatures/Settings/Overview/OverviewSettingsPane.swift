import Charts
import SwiftUI
import WaftCore

struct OverviewSettingsPane: View {
    let statistics: StatisticsModel

    var body: some View {
        RecentSection(statistics: statistics.statistics)

        AllTimeSection(statistics: statistics)
    }
}

private struct RecentSection: View {
    private static let dayCount = 7

    let statistics: DictationStatistics

    private var days: [(date: Date, day: DictationStatistics.Day)] {
        statistics.daily(last: Self.dayCount, endingOn: Date())
    }

    var body: some View {
        let recent = statistics.total(last: Self.dayCount, endingOn: Date())

        SettingsSection("Last 7 days", subtitle: "Counted on this Mac: words and time, never the text.") {
            HStack(spacing: 0) {
                Metric(value: recent.words.formatted(), label: "words")
                Metric(value: savedTime(in: recent), label: "saved over typing")
                Metric(value: speed(in: recent), label: "words a minute")
            }

            RowDivider()

            if days.allSatisfy({ $0.day.words == 0 }) {
                EmptyRow("No dictations in the last 7 days")
            } else {
                WordsChart(days: days)
                    .settingsRowPadding()
            }
        }
        .motion(Motion.layout, value: recent.words)
    }

    private func savedTime(in recent: DictationStatistics.Day) -> String {
        recent.savedOverTyping.formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }

    private func speed(in recent: DictationStatistics.Day) -> String {
        guard let wordsPerMinute = recent.wordsPerMinute else { return "–" }

        return wordsPerMinute.formatted()
    }
}

private struct AllTimeSection: View {
    let statistics: StatisticsModel

    private var total: DictationStatistics.Day {
        statistics.statistics.allTime
    }

    var body: some View {
        SettingsSection("All time") {
            HStack(spacing: 0) {
                Metric(value: total.words.formatted(), label: "words")
                Metric(value: total.dictations.formatted(), label: "dictations")
                Metric(value: statistics.statistics.streak(endingOn: Date()).formatted(), label: "days in a row")
            }
        } footer: {
            Button("Reset Statistics…", role: .destructive, action: confirmReset)
                .disabled(statistics.statistics.days.isEmpty)
        }
        .motion(Motion.layout, value: total.words)
    }

    private func confirmReset() {
        let confirmation = Confirmation(
            message: String(localized: "Reset your dictation statistics?"),
            detail: String(localized: "This sets the word and time counts back to zero. Your history stays."),
            action: String(localized: "Reset Statistics"),
        )

        if confirmation.ask() {
            statistics.reset()
        }
    }
}

private struct Metric: View {
    let value: String
    let label: LocalizedStringKey

    var body: some View {
        VStack(spacing: Metrics.labelSpacing) {
            Text(value)
                .font(.metric)
                .monospacedDigit()
                .contentTransition(.numericText())

            Text(label)
                .detailText()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Metrics.metricPadding)
        .accessibilityElement(children: .combine)
    }
}

private struct WordsChart: View {
    let days: [(date: Date, day: DictationStatistics.Day)]

    var body: some View {
        Chart(days, id: \.date) { item in
            BarMark(
                x: .value("Day", item.date, unit: .day),
                y: .value("Words", item.day.words),
                width: .ratio(0.6),
            )
            .foregroundStyle(Palette.accent.gradient)
            .cornerRadius(3)
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.day(), centered: true)
            }
        }
        .frame(height: 96)
        .accessibilityLabel("Words dictated each day for the last 7 days")
    }
}
