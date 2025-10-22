import SwiftUI

enum ColorPalette {
    static func base(_ c: Character) -> Color {
        switch c {
        case "A": return Color(red: 0.98, green: 0.80, blue: 0.20)
        case "T": return Color(red: 0.95, green: 0.28, blue: 0.28)
        case "G": return Color(red: 0.26, green: 0.78, blue: 0.62)
        case "C": return Color(red: 0.03, green: 0.29, blue: 0.60)
        default:   return .gray
        }
    }
    static let chromosome = Color(red: 0.85, green: 0.89, blue: 0.94)
    static let chromosomeDark = Color(red: 0.76, green: 0.80, blue: 0.88)
    static let geneBlue = Color(red: 0.18, green: 0.49, blue: 0.92)
}


