import SwiftUI

/// Carte École — prête pour Cabanga (voir `CabangaProvider`), données
/// d'exemple en attendant.
struct SchoolCard: View {
    var model: DashboardModel

    var body: some View {
        GlassCard(icon: "graduationcap.fill", title: "École", iconColor: Theme.series4,
                  trailing: AnyView(sourceBadge)) {
            if let school = model.school {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        StatTile(value: averageText(school),
                                 label: "Moyenne générale",
                                 color: Theme.series4)
                        StatTile(value: studyText(school.studyMinutesToday),
                                 label: "Étude aujourd'hui")
                    }

                    section(title: "Devoirs à rendre") {
                        ForEach(school.homework) { hw in
                            row(subject: hw.subject, title: hw.title, date: hw.dueDate)
                        }
                        if school.homework.isEmpty {
                            EmptyHint(text: "Aucun devoir. 🎉")
                        }
                    }

                    section(title: "Contrôles à venir") {
                        ForEach(school.exams) { exam in
                            row(subject: exam.subject, title: exam.title, date: exam.date, highlight: true)
                        }
                        if school.exams.isEmpty {
                            EmptyHint(text: "Aucun contrôle planifié.")
                        }
                    }
                }
            } else {
                EmptyHint(text: model.isRefreshing
                          ? "Chargement…"
                          : "Données scolaires indisponibles.")
            }
        }
    }

    private var sourceBadge: AnyView {
        AnyView(
            Text(model.schoolIsLive ? "Cabanga" : "Démo")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(model.schoolIsLive ? Theme.series4 : Theme.textMuted)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.white.opacity(0.08)))
        )
    }

    private func averageText(_ school: SchoolSummary) -> String {
        guard let avg = school.average else { return "—" }
        return "\(avg.formatted(.number.precision(.fractionLength(0...1))))/\(school.averageScale.formatted(.number.precision(.fractionLength(0))))"
    }

    private func studyText(_ minutes: Int) -> String {
        minutes >= 60 ? DateUtils.formatHours(Double(minutes) / 60) : "\(minutes) min"
    }

    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.textMuted)
                .textCase(.uppercase)
                .kerning(0.5)
            content()
        }
    }

    private func row(subject: String, title: String, date: Date, highlight: Bool = false) -> some View {
        HStack(spacing: 10) {
            Text(subject)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(highlight ? Theme.series5 : Theme.series4)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill((highlight ? Theme.series5 : Theme.series4).opacity(0.15)))

            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)

            Spacer()

            Text(relativeDay(date))
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(Theme.textMuted)
        }
    }

    private func relativeDay(_ date: Date) -> String {
        let days = DateUtils.daysUntil(date)
        switch days {
        case 0: return "aujourd'hui"
        case 1: return "demain"
        default: return "dans \(days) j"
        }
    }
}
