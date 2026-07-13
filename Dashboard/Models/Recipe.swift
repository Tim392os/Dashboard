import Foundation
import SwiftData

/// Recette testée, avec note sur 5 et retour libre.
@Model
final class Recipe {
    var name: String
    var rating: Int // 0…5
    var feedback: String
    var testedAt: Date

    init(name: String, rating: Int = 0, feedback: String = "", testedAt: Date = .now) {
        self.name = name
        self.rating = rating
        self.feedback = feedback
        self.testedAt = testedAt
    }
}
