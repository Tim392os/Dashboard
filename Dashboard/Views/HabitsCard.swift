import SwiftUI
import SwiftData

/// Habitudes du jour : sommeil (Apple Santé), fruits/légumes (saisie rapide),
/// temps d'écran (saisie manuelle — Apple n'expose pas les totaux Temps
/// d'écran aux apps tierces). Génère une série (streak).
struct HabitsCard: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \HabitLog.day, order: .reverse) private var logs: [HabitLog]
    var model: DashboardModel

    @State private var showScreenTimeEditor = false

    private var todayLog: HabitLog? {
        logs.first { $0.day == DateUtils.startOfToday() }
    }

    private var streak: Int { HabitStreak.current(logs: logs) }

    var body: some View {
        GlassCard(icon: "heart.fill", title: "Habitudes", iconColor: Theme.series5,
                  trailing: AnyView(streakBadge)) {
            VStack(spacing: 12) {
                sleepRow
                fruitsRow
                screenTimeRow
            }
        }
        .onAppear(perform: syncSleep)
        .onChange(of: model.sleepHours) { _, _ in syncSleep() }
        .sheet(isPresented: $showScreenTimeEditor) {
            ScreenTimeSheet(log: ensureTodayLog())
        }
    }

    private var streakBadge: AnyView {
        AnyView(
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
                Text("\(streak)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
            }
            .foregroundStyle(streak > 0 ? Theme.series3 : Theme.textMuted)
        )
    }

    private var sleepRow: some View {
        habitRow(icon: "moon.zzz.fill", color: Theme.series4, title: "Sommeil") {
            if let hours = todayLog?.sleepHours, hours > 0 {
                Text(DateUtils.formatHours(hours))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            } else {
                Text(HealthKitService.shared.isAvailable ? "En attente d'Apple Santé" : "Apple Santé indisponible")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textMuted)
            }
        }
    }

    private var fruitsRow: some View {
        habitRow(icon: "carrot.fill", color: Theme.series2,
                 title: "Fruits & légumes") {
            HStack(spacing: 12) {
                stepButton("minus") { adjustFruits(-1) }
                Text("\(todayLog?.fruitsVeggies ?? 0)/\(HabitLog.fruitsVeggiesTarget)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle((todayLog?.isComplete ?? false) ? Theme.good : Theme.textPrimary)
                    .contentTransition(.numericText())
                    .frame(minWidth: 40)
                stepButton("plus") { adjustFruits(1) }
            }
        }
    }

    private var screenTimeRow: some View {
        habitRow(icon: "iphone", color: Theme.accent, title: "Temps d'écran") {
            Button {
                showScreenTimeEditor = true
            } label: {
                let minutes = todayLog?.screenTimeMinutes ?? 0
                Text(minutes > 0 ? DateUtils.formatHours(Double(minutes) / 60) : "Saisir")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(minutes > 0 ? Theme.textPrimary : Theme.accent)
            }
            .buttonStyle(.plain)
        }
    }

    private func habitRow(icon: String, color: Color, title: String,
                          @ViewBuilder value: () -> some View) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(color)
                .frame(width: 28)
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            value()
        }
        .padding(.vertical, 4)
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.white.opacity(0.10)))
        }
        .buttonStyle(.plain)
    }

    private func ensureTodayLog() -> HabitLog {
        HabitStreak.todayLog(context: context)
    }

    private func adjustFruits(_ delta: Int) {
        let log = ensureTodayLog()
        withAnimation(Theme.springAnimation) {
            log.fruitsVeggies = max(0, log.fruitsVeggies + delta)
        }
    }

    /// Recopie les heures Apple Santé dans le journal du jour (pour la série
    /// et l'historique hors-ligne).
    private func syncSleep() {
        guard let hours = model.sleepHours, hours > 0 else { return }
        let log = ensureTodayLog()
        if abs(log.sleepHours - hours) > 0.01 {
            log.sleepHours = hours
        }
    }
}

private struct ScreenTimeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var log: HabitLog
    @State private var hours: Double = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Temps d'écran aujourd'hui — \(DateUtils.formatHours(hours))") {
                    Slider(value: $hours, in: 0...12, step: 0.25)
                }
                Text("Apple ne fournit pas d'API publique pour lire le total Temps d'écran : la valeur se saisit manuellement (Réglages → Temps d'écran).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Temps d'écran")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        log.screenTimeMinutes = Int(hours * 60)
                        dismiss()
                    }
                }
            }
        }
        .onAppear { hours = Double(log.screenTimeMinutes) / 60 }
        .presentationDetents([.height(280)])
        .preferredColorScheme(.dark)
    }
}
