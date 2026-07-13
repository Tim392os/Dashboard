import SwiftUI
import SwiftData

/// Tâches du jour : cocher, ajouter, modifier, supprimer.
/// Les tâches terminées sont archivées automatiquement au changement de jour.
struct TasksCard: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<TaskItem> { !$0.isArchived },
           sort: \TaskItem.createdAt)
    private var tasks: [TaskItem]

    @State private var newTitle = ""
    @State private var editingTask: TaskItem?
    @FocusState private var addFieldFocused: Bool

    var body: some View {
        GlassCard(icon: "checkmark.circle.fill", title: "Tâches", iconColor: Theme.good,
                  trailing: AnyView(counter)) {
            VStack(spacing: 2) {
                if tasks.isEmpty {
                    EmptyHint(text: "Aucune tâche pour aujourd'hui — ajoutes-en une ci-dessous.")
                }
                ForEach(tasks) { task in
                    TaskRow(task: task,
                            onEdit: { editingTask = task },
                            onDelete: { delete(task) })
                }
                addField
            }
        }
        .sheet(item: $editingTask) { task in
            TaskEditSheet(task: task)
        }
    }

    private var counter: AnyView {
        AnyView(
            Text("\(tasks.filter(\.isDone).count)/\(tasks.count)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textMuted)
        )
    }

    private var addField: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle")
                .foregroundStyle(Theme.textMuted)
            TextField("Nouvelle tâche", text: $newTitle)
                .focused($addFieldFocused)
                .foregroundStyle(Theme.textPrimary)
                .submitLabel(.done)
                .onSubmit(addTask)
        }
        .padding(.vertical, 10)
    }

    private func addTask() {
        let title = newTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        withAnimation(Theme.springAnimation) {
            context.insert(TaskItem(title: title))
        }
        newTitle = ""
        addFieldFocused = true
    }

    private func delete(_ task: TaskItem) {
        withAnimation(Theme.springAnimation) {
            context.delete(task)
        }
    }
}

private struct TaskRow: View {
    @Bindable var task: TaskItem
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(Theme.springAnimation) { task.toggle() }
            } label: {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(task.isDone ? Theme.good : Theme.textMuted)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.system(size: 15))
                .foregroundStyle(task.isDone ? Theme.textMuted : Theme.textPrimary)
                .strikethrough(task.isDone, color: Theme.textMuted)
                .lineLimit(2)

            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .contextMenu {
            Button("Modifier", systemImage: "pencil", action: onEdit)
            Button("Supprimer", systemImage: "trash", role: .destructive, action: onDelete)
        }
        .swipeActions { // effectif si la carte passe un jour en List
            Button("Supprimer", role: .destructive, action: onDelete)
        }
    }
}

private struct TaskEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var task: TaskItem

    var body: some View {
        NavigationStack {
            Form {
                TextField("Titre", text: $task.title, axis: .vertical)
                Button("Supprimer la tâche", role: .destructive) {
                    context.delete(task)
                    dismiss()
                }
            }
            .navigationTitle("Modifier la tâche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
        .presentationDetents([.height(260)])
        .preferredColorScheme(.dark)
    }
}
