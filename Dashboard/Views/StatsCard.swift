import SwiftUI
import SwiftData
import Charts

/// Statistiques : série d'habitudes, heures d'entraînement de l'année
/// (graphique), recettes testées + historique noté, argent économisé.
struct StatsCard: View {
    @Query(sort: \HabitLog.day, order: .reverse) private var logs: [HabitLog]
    @Query(sort: \Recipe.testedAt, order: .reverse) private var recipes: [Recipe]
    @Query private var finances: [FinanceState]
    var model: DashboardModel

    @State private var showRecipes = false

    private var streak: Int { HabitStreak.current(logs: logs) }
    private var moneySaved: Double { finances.first?.moneySaved ?? 0 }

    var body: some View {
        GlassCard(icon: "chart.bar.fill", title: "Statistiques", iconColor: Theme.series3) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    StatTile(value: "\(streak) j",
                             label: "Série d'habitudes",
                             color: streak > 0 ? Theme.series3 : Theme.textPrimary)
                    StatTile(value: DateUtils.formatHours(model.training?.yearTotalHours ?? 0),
                             label: "Entraînement cette année")
                }
                HStack(spacing: 10) {
                    StatTile(value: "\(recipes.count)", label: "Recettes testées")
                    StatTile(value: moneySaved.asEuro,
                             label: "Argent économisé",
                             color: Theme.good)
                }

                if let hours = model.training?.yearHoursByMonth, !hours.isEmpty {
                    trainingChart(hours)
                }

                Button {
                    showRecipes = true
                } label: {
                    HStack {
                        Image(systemName: "fork.knife")
                        Text("Historique des recettes")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showRecipes) {
            RecipesView()
        }
    }

    private func trainingChart(_ hoursByMonth: [Int: Double]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Heures d'entraînement par mois")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.textMuted)
                .textCase(.uppercase)
                .kerning(0.5)

            Chart {
                ForEach(hoursByMonth.sorted(by: { $0.key < $1.key }), id: \.key) { month, hours in
                    BarMark(
                        x: .value("Mois", monthLabel(month)),
                        y: .value("Heures", hours),
                        width: .ratio(0.55)
                    )
                    .foregroundStyle(Theme.accent.gradient)
                    .cornerRadius(4)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing) { _ in
                    AxisGridLine().foregroundStyle(Theme.hairline)
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .frame(height: 140)
        }
    }

    private func monthLabel(_ month: Int) -> String {
        let symbols = DateUtils.calendar.shortMonthSymbols
        let name = symbols[(month - 1) % 12]
        return String(name.prefix(1)).uppercased() + name.dropFirst().prefix(2)
    }
}
