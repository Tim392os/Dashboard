import Foundation
import SwiftData

@Model
final class TaskItem {
    var title: String
    var isDone: Bool
    var createdAt: Date
    var completedAt: Date?
    /// Les tâches terminées sont archivées automatiquement au changement de jour.
    var isArchived: Bool

    init(title: String) {
        self.title = title
        self.isDone = false
        self.createdAt = .now
        self.completedAt = nil
        self.isArchived = false
    }

    func toggle() {
        isDone.toggle()
        completedAt = isDone ? .now : nil
    }
}

enum TaskArchiver {
    /// Archive les tâches terminées avant aujourd'hui. À appeler au retour au premier plan.
    static func archiveCompletedTasks(context: ModelContext) {
        let startOfToday = DateUtils.startOfToday()
        let predicate = #Predicate<TaskItem> { task in
            task.isDone && !task.isArchived
        }
        guard let done = try? context.fetch(FetchDescriptor(predicate: predicate)) else { return }
        for task in done where (task.completedAt ?? task.createdAt) < startOfToday {
            task.isArchived = true
        }
    }
}
