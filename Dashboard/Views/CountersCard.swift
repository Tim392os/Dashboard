import SwiftUI
import SwiftData

/// Compteurs de jours (vacances, anniversaire, Noël, voyage…).
/// Les dates sont modifiables au toucher ; les événements annuels avancent
/// automatiquement à la prochaine occurrence.
struct CountersCard: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Countdown.sortOrder) private var countdowns: [Countdown]
    @State private var editingCountdown: Countdown?
    @State private var showAdd = false

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        GlassCard(icon: "hourglass", title: "Compteurs", iconColor: Theme.series3,
                  trailing: AnyView(addButton)) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(countdowns) { countdown in
                    tile(countdown)
                        .onTapGesture { editingCountdown = countdown }
                        .contextMenu {
                            Button("Modifier", systemImage: "pencil") { editingCountdown = countdown }
                            Button("Supprimer", systemImage: "trash", role: .destructive) {
                                withAnimation(Theme.springAnimation) { context.delete(countdown) }
                            }
                        }
                }
            }
        }
        .sheet(item: $editingCountdown) { countdown in
            CountdownEditSheet(countdown: countdown)
        }
        .sheet(isPresented: $showAdd) {
            CountdownEditSheet(countdown: nil)
        }
    }

    private var addButton: AnyView {
        AnyView(
            Button {
                showAdd = true
            } label: {
                Image(systemName: "plus.circle")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.textMuted)
            }
            .buttonStyle(.plain)
        )
    }

    private func tile(_ countdown: Countdown) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: countdown.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.series3)
                Spacer()
            }
            Text("\(countdown.daysRemaining)")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .contentTransition(.numericText())
            Text("jours · \(countdown.name)")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textMuted)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
        }
    }
}

private struct CountdownEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    /// Nil = création d'un nouveau compteur.
    let countdown: Countdown?

    @State private var name = ""
    @State private var date = DateUtils.startOfToday()
    @State private var icon = "star.fill"
    @State private var repeatsYearly = false

    private let icons = ["star.fill", "sun.max.fill", "gift.fill", "snowflake",
                         "airplane", "graduationcap.fill", "bicycle", "heart.fill"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nom de l'événement", text: $name)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Toggle("Chaque année", isOn: $repeatsYearly)
                }
                Section("Icône") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8)) {
                        ForEach(icons, id: \.self) { candidate in
                            Image(systemName: candidate)
                                .font(.system(size: 17))
                                .foregroundStyle(candidate == icon ? Theme.series3 : Theme.textMuted)
                                .frame(width: 34, height: 34)
                                .background {
                                    if candidate == icon {
                                        Circle().fill(Theme.series3.opacity(0.2))
                                    }
                                }
                                .onTapGesture { icon = candidate }
                        }
                    }
                }
            }
            .navigationTitle(countdown == nil ? "Nouveau compteur" : "Modifier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            if let countdown {
                name = countdown.name
                date = countdown.date
                icon = countdown.icon
                repeatsYearly = countdown.repeatsYearly
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }

    private func save() {
        if let countdown {
            countdown.name = name
            countdown.date = date
            countdown.icon = icon
            countdown.repeatsYearly = repeatsYearly
        } else {
            context.insert(Countdown(name: name, icon: icon, date: date,
                                     repeatsYearly: repeatsYearly, sortOrder: 99))
        }
        dismiss()
    }
}
