import SwiftUI
import SwiftData

/// Carte Finances (BNP Paribas).
/// Les API PSD2 de BNP sont réservées aux prestataires agréés : par défaut la
/// carte fonctionne en saisie manuelle sécurisée (montants uniquement, jamais
/// d'identifiants). Un `BankDataProvider` (agrégateur agréé) peut prendre le
/// relais automatiquement — voir `BankProvider.swift`.
struct FinanceCard: View {
    @Environment(\.modelContext) private var context
    @Query private var finances: [FinanceState]
    var model: DashboardModel

    @State private var showEditor = false

    private var state: FinanceState? { finances.first }

    /// Le provider bancaire (s'il est connecté) prime sur la saisie manuelle.
    private var available: Double { model.bank?.available ?? state?.available ?? 0 }
    private var savings: Double { model.bank?.savings ?? state?.savings ?? 0 }
    private var expenses: Double { model.bank?.monthExpenses ?? state?.monthExpenses ?? 0 }

    var body: some View {
        GlassCard(icon: "eurosign.circle.fill", title: "Finances", iconColor: Theme.good,
                  trailing: AnyView(editButton)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    StatTile(value: available.asEuro, label: "Disponible", color: Theme.textPrimary)
                    StatTile(value: savings.asEuro, label: "Épargne", color: Theme.good)
                    StatTile(value: expenses.asEuro, label: "Dépenses du mois", color: Theme.series5)
                }

                if let state {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Objectif d'épargne")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textSecondary)
                            Spacer()
                            Text("\(savings.asEuro) / \(state.savingsGoal.asEuro)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                        }
                        ProgressBar(progress: state.savingsGoal > 0 ? min(savings / state.savingsGoal, 1) : 0,
                                    color: Theme.good)
                        Text((state.savingsGoal > 0 ? min(savings / state.savingsGoal, 1) : 0)
                            .formatted(.percent.precision(.fractionLength(0))))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.textMuted)
                    }
                }

                Text(model.bank != nil
                     ? "Connecté via Open Banking (jeton sécurisé dans le trousseau)."
                     : "Saisie manuelle — aucun identifiant bancaire n'est stocké.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .sheet(isPresented: $showEditor) {
            if let state {
                FinanceEditSheet(state: state)
            }
        }
    }

    private var editButton: AnyView {
        AnyView(
            Button {
                showEditor = true
            } label: {
                Image(systemName: "pencil.circle")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.textMuted)
            }
            .buttonStyle(.plain)
        )
    }
}

private struct FinanceEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var state: FinanceState

    var body: some View {
        NavigationStack {
            Form {
                Section("Montants (€)") {
                    LabeledContent("Disponible") {
                        TextField("0", value: $state.available, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Épargne") {
                        TextField("0", value: $state.savings, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Dépenses du mois") {
                        TextField("0", value: $state.monthExpenses, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Section("Objectifs") {
                    LabeledContent("Objectif d'épargne") {
                        TextField("0", value: $state.savingsGoal, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Argent économisé (stats)") {
                        TextField("0", value: $state.moneySaved, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Finances")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        state.updatedAt = .now
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.dark)
    }
}
