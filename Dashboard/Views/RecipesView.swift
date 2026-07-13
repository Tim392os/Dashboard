import SwiftUI
import SwiftData

/// Historique et notation des recettes testées.
struct RecipesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Recipe.testedAt, order: .reverse) private var recipes: [Recipe]

    @State private var newName = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Nouvelle recette testée", text: $newName)
                            .submitLabel(.done)
                            .onSubmit(addRecipe)
                        Button("Ajouter", action: addRecipe)
                            .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                Section("\(recipes.count) recettes") {
                    ForEach(recipes) { recipe in
                        RecipeRow(recipe: recipe)
                    }
                    .onDelete { indexSet in
                        for index in indexSet { context.delete(recipes[index]) }
                    }
                }
            }
            .navigationTitle("Recettes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func addRecipe() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        context.insert(Recipe(name: name))
        newName = ""
    }
}

private struct RecipeRow: View {
    @Bindable var recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(recipe.name)
                    .font(.system(size: 15, weight: .medium))
                Spacer()
                Text(recipe.testedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        recipe.rating = (recipe.rating == star) ? 0 : star
                    } label: {
                        Image(systemName: star <= recipe.rating ? "star.fill" : "star")
                            .font(.system(size: 14))
                            .foregroundStyle(star <= recipe.rating ? Theme.series3 : Theme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            TextField("Retour sur la recette…", text: $recipe.feedback, axis: .vertical)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
