import Foundation
import SwiftData

enum NoteCategory: String, Codable, CaseIterable {
    case idea, shopping, link

    var label: String {
        switch self {
        case .idea: "Idée"
        case .shopping: "À acheter"
        case .link: "Lien"
        }
    }

    var icon: String {
        switch self {
        case .idea: "lightbulb"
        case .shopping: "cart"
        case .link: "link"
        }
    }
}

@Model
final class QuickNote {
    var categoryRaw: String
    var text: String
    var createdAt: Date

    var category: NoteCategory {
        get { NoteCategory(rawValue: categoryRaw) ?? .idea }
        set { categoryRaw = newValue.rawValue }
    }

    init(category: NoteCategory, text: String) {
        self.categoryRaw = category.rawValue
        self.text = text
        self.createdAt = .now
    }
}
