import SwiftUI
import SwiftData

/// Page principale : toutes les cartes de la journée, sur fond noir profond.
struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @State private var model = DashboardModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.cardSpacing) {
                        header

                        TasksCard()
                        GoalsCard()
                        BikeCard(model: model)
                        SchoolCard(model: model)
                        HabitsCard(model: model)
                        StatsCard(model: model)
                        FinanceCard(model: model)
                        CountersCard()
                        NotesCard()

                        footer
                    }
                    .padding(.horizontal, Theme.pageMargin)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
                .refreshable { await model.refresh() }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .task { await model.refresh() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            TaskArchiver.archiveCompletedTasks(context: context)
            Task { await model.refresh() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textMuted)
                .textCase(.uppercase)
                .kerning(1)
            Text(greeting)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Bonjour Tim"
        case 12..<18: return "Bon après-midi"
        default: return "Bonsoir Tim"
        }
    }

    private var footer: some View {
        Group {
            if let last = model.lastRefresh {
                Text("Actualisé à \(last.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.top, 8)
            }
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [TaskItem.self, Goal.self, HabitLog.self, Recipe.self,
                              QuickNote.self, Countdown.self, FinanceState.self],
                        inMemory: true)
        .preferredColorScheme(.dark)
}
