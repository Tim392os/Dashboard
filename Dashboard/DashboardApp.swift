import SwiftUI
import SwiftData

@main
struct DashboardApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for:
                TaskItem.self,
                Goal.self,
                HabitLog.self,
                Recipe.self,
                QuickNote.self,
                Countdown.self,
                FinanceState.self
            )
        } catch {
            fatalError("Impossible d'initialiser la base de données locale : \(error)")
        }
        SeedData.seedIfNeeded(context: ModelContext(container))
    }

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
        .modelContainer(container)
    }
}
