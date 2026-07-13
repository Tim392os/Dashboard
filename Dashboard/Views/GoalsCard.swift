import SwiftUI
import SwiftData

/// Trois cartes d'objectifs : semaine, mois, année — texte, progression,
/// pourcentage exact et date limite. Tout est modifiable au toucher.
struct GoalsCard: View {
    @Query(sort: \Goal.deadline) private var goals: [Goal]
    @State private var editingGoal: Goal?

    private var ordered: [Goal] {
        GoalPeriod.allCases.compactMap { period in
            goals.first { $0.period == period }
        }
    }

    var body: some View {
        VStack(spacing: Theme.cardSpacing) {
            ForEach(ordered) { goal in
                GoalCardView(goal: goal)
                    .onTapGesture { editingGoal = goal }
            }
        }
        .sheet(item: $editingGoal) { goal in
            GoalEditSheet(goal: goal)
        }
    }
}

private struct GoalCardView: View {
    let goal: Goal

    private var color: Color {
        switch goal.period {
        case .week: Theme.accent
        case .month: Theme.series4
        case .year: Theme.series3
        }
    }

    var body: some View {
        GlassCard(icon: goal.period.icon, title: goal.period.label, iconColor: color,
                  trailing: AnyView(percentBadge)) {
            VStack(alignment: .leading, spacing: 10) {
                Text(goal.text)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(3)

                ProgressBar(progress: goal.progress, color: color)

                HStack {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 11))
                    Text("Échéance : \(DateUtils.shortDate(goal.deadline))")
                        .font(.system(size: 12))
                    Spacer()
                    Text("\(DateUtils.daysUntil(goal.deadline)) j restants")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                }
                .foregroundStyle(Theme.textMuted)
            }
        }
    }

    private var percentBadge: AnyView {
        AnyView(
            Text(goal.progress.formatted(.percent.precision(.fractionLength(0))))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        )
    }
}

private struct GoalEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var goal: Goal

    var body: some View {
        NavigationStack {
            Form {
                Section("Objectif") {
                    TextField("Texte de l'objectif", text: $goal.text, axis: .vertical)
                }
                Section("Progression — \(goal.progress.formatted(.percent.precision(.fractionLength(0))))") {
                    Slider(value: $goal.progress, in: 0...1, step: 0.01)
                }
                Section("Date limite") {
                    DatePicker("Échéance", selection: $goal.deadline, displayedComponents: .date)
                }
            }
            .navigationTitle(goal.period.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }
}
