import SwiftUI

struct BasePair: Identifiable, Hashable {
    let id: Int
    let left: Character
    let right: Character
}

enum GenomeFeatureType {
    case gene, variant, cpg
}

struct GeneMark: Identifiable {
    let id: UUID
    let name: String
    let start: Int
    let end: Int
    let type: GenomeFeatureType
    let color: Color
    
    init(name: String, start: Int, end: Int, type: GenomeFeatureType, color: Color) {
        self.id = UUID()
        self.name = name
        self.start = start
        self.end = end
        self.type = type
        self.color = color
    }
}

extension GeneMark: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(start)
        hasher.combine(end)
    }
    
    static func == (lhs: GeneMark, rhs: GeneMark) -> Bool {
        return lhs.name == rhs.name && lhs.start == rhs.start && lhs.end == rhs.end
    }
}


