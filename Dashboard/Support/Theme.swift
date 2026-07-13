import SwiftUI

/// Palette et constantes de design de l'app.
/// Fond noir profond, cartes translucides, accent bleu.
/// Les couleurs de séries (graphiques) sont validées pour un fond sombre
/// et assignées dans un ordre fixe — ne pas les réordonner.
enum Theme {
    // MARK: Fond
    static let background = Color(red: 0.02, green: 0.02, blue: 0.03)

    // MARK: Encres
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.765, green: 0.76, blue: 0.718)
    static let textMuted = Color(red: 0.54, green: 0.53, blue: 0.51)

    // MARK: Accent & séries (ordre fixe)
    static let accent = Color(hex: 0x3987E5)      // bleu — série 1
    static let series2 = Color(hex: 0x199E70)     // vert d'eau
    static let series3 = Color(hex: 0xC98500)     // jaune
    static let series4 = Color(hex: 0x9085E9)     // violet
    static let series5 = Color(hex: 0xE66767)     // rouge

    // MARK: Statuts (réservés — jamais utilisés comme couleur de série)
    static let good = Color(hex: 0x0CA30C)
    static let warning = Color(hex: 0xFAB219)
    static let critical = Color(hex: 0xD03B3B)

    // MARK: Métriques
    static let cardCornerRadius: CGFloat = 26
    static let cardPadding: CGFloat = 18
    static let pageMargin: CGFloat = 20
    static let cardSpacing: CGFloat = 16

    static let cardStroke = Color.white.opacity(0.08)
    static let hairline = Color.white.opacity(0.09)

    static let springAnimation: Animation = .spring(response: 0.4, dampingFraction: 0.8)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
