import Foundation

enum DateUtils {
    static var calendar: Calendar { Calendar.current }

    static func startOfToday() -> Date {
        calendar.startOfDay(for: .now)
    }

    static func daysUntil(_ date: Date) -> Int {
        let start = calendar.startOfDay(for: .now)
        let end = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    /// Prochaine occurrence d'un jour/mois (ex. anniversaire, Noël).
    static func nextOccurrence(day: Int, month: Int) -> Date {
        var comps = DateComponents()
        comps.day = day
        comps.month = month
        let today = startOfToday()
        return calendar.nextDate(after: today.addingTimeInterval(-1),
                                 matching: comps,
                                 matchingPolicy: .nextTime) ?? today
    }

    static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.wide))
    }

    static func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return m == 0 ? "\(h) h" : "\(h) h \(String(format: "%02d", m))"
    }
}
