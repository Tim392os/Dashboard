import SwiftUI

/// Carte Vélo — alimentée par TrainingPeaks quand l'API est connectée,
/// sinon par les données d'exemple du mode démo.
struct BikeCard: View {
    var model: DashboardModel

    var body: some View {
        GlassCard(icon: "bicycle", title: "Vélo", iconColor: Theme.series2,
                  trailing: AnyView(sourceBadge)) {
            if let training = model.training {
                VStack(alignment: .leading, spacing: 14) {
                    if let race = training.nextRace {
                        raceHero(race)
                    } else {
                        EmptyHint(text: "Aucune course planifiée.")
                    }

                    if !training.upcomingWorkouts.isEmpty {
                        workoutsList(training.upcomingWorkouts)
                    }

                    if let load = training.recentLoad {
                        loadRow(load)
                    }
                }
            } else {
                EmptyHint(text: model.isRefreshing
                          ? "Chargement…"
                          : "Données d'entraînement indisponibles.")
            }
        }
    }

    private var sourceBadge: AnyView {
        AnyView(
            Text(model.trainingIsLive ? "TrainingPeaks" : "Démo")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(model.trainingIsLive ? Theme.series2 : Theme.textMuted)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.white.opacity(0.08)))
        )
    }

    private func raceHero(_ race: Race) -> some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(spacing: 0) {
                Text("\(race.daysRemaining)")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.series2)
                    .contentTransition(.numericText())
                Text("jours")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
            }
            .frame(width: 70)

            VStack(alignment: .leading, spacing: 3) {
                Text("Prochaine course")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                    .textCase(.uppercase)
                    .kerning(0.5)
                Text(race.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                Text(DateUtils.shortDate(race.date))
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.series2.opacity(0.10))
        }
    }

    private func workoutsList(_ workouts: [PlannedWorkout]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Prochains entraînements")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.textMuted)
                .textCase(.uppercase)
                .kerning(0.5)

            ForEach(workouts) { workout in
                HStack {
                    Text(workout.date.formatted(.dateTime.weekday(.abbreviated)))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.series2)
                        .frame(width: 40, alignment: .leading)
                    Text(workout.title)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text("\(workout.durationMinutes) min")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
    }

    private func loadRow(_ load: TrainingLoad) -> some View {
        HStack(spacing: 10) {
            StatTile(value: DateUtils.formatHours(load.last7DaysHours), label: "7 derniers jours")
            StatTile(value: load.last7DaysTSS.formatted(.number.precision(.fractionLength(0))), label: "TSS · 7 jours")
            if let ctl = load.fitnessCTL {
                StatTile(value: ctl.formatted(.number.precision(.fractionLength(0))), label: "Forme (CTL)")
            }
        }
    }
}
