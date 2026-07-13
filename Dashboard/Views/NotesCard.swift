import SwiftUI
import SwiftData

/// Notes rapides : idées, choses à acheter, liens utiles — avec recherche
/// instantanée (filtrage local à la frappe).
struct NotesCard: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \QuickNote.createdAt, order: .reverse) private var notes: [QuickNote]

    @State private var searchText = ""
    @State private var newText = ""
    @State private var newCategory: NoteCategory = .idea
    @FocusState private var addFieldFocused: Bool

    private var filtered: [QuickNote] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return notes }
        return notes.filter {
            $0.text.localizedCaseInsensitiveContains(query) ||
            $0.category.label.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        GlassCard(icon: "note.text", title: "Notes rapides", iconColor: Theme.accent) {
            VStack(spacing: 12) {
                searchField

                if filtered.isEmpty {
                    EmptyHint(text: searchText.isEmpty
                              ? "Aucune note pour l'instant."
                              : "Aucun résultat pour « \(searchText) ».")
                }

                ForEach(filtered.prefix(8)) { note in
                    noteRow(note)
                }

                addRow
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textMuted)
            TextField("Rechercher…", text: $searchText)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textPrimary)
            if !searchText.isEmpty {
                Button {
                    withAnimation(Theme.springAnimation) { searchText = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Capsule().fill(Color.white.opacity(0.07)))
    }

    private func noteRow(_ note: QuickNote) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: note.category.icon)
                .font(.system(size: 13))
                .foregroundStyle(categoryColor(note.category))
                .frame(width: 22)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                if note.category == .link,
                   let url = URL(string: note.text),
                   url.scheme?.hasPrefix("http") == true {
                    Link(note.text, destination: url)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.accent)
                        .lineLimit(1)
                } else {
                    Text(note.text)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(3)
                }
                Text(note.category.label)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button("Supprimer", systemImage: "trash", role: .destructive) {
                withAnimation(Theme.springAnimation) { context.delete(note) }
            }
        }
    }

    private var addRow: some View {
        VStack(spacing: 8) {
            Divider().overlay(Theme.hairline)
            HStack(spacing: 8) {
                Menu {
                    ForEach(NoteCategory.allCases, id: \.self) { category in
                        Button(category.label, systemImage: category.icon) {
                            newCategory = category
                        }
                    }
                } label: {
                    Image(systemName: newCategory.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(categoryColor(newCategory))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }

                TextField("Nouvelle note (\(newCategory.label.lowercased()))", text: $newText)
                    .font(.system(size: 14))
                    .focused($addFieldFocused)
                    .submitLabel(.done)
                    .onSubmit(addNote)
            }
        }
    }

    private func categoryColor(_ category: NoteCategory) -> Color {
        switch category {
        case .idea: Theme.series3
        case .shopping: Theme.series2
        case .link: Theme.accent
        }
    }

    private func addNote() {
        let text = newText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        withAnimation(Theme.springAnimation) {
            context.insert(QuickNote(category: newCategory, text: text))
        }
        newText = ""
        addFieldFocused = true
    }
}
