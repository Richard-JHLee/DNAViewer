import SwiftUI

private func complement(of base: Character) -> Character {
    switch base {
    case "A": return "T"
    case "T": return "A"
    case "G": return "C"
    case "C": return "G"
    default:  return "N"
    }
}

extension DNASequence {
    var basePairs: [BasePair] {
        let chars = Array(sequence)
        return chars.enumerated().map { idx, c in
            BasePair(id: idx, left: c, right: complement(of: c))
        }
    }
    
    var geneMarks: [GeneMark] {
        guard length > 0 else { return [] }
        let b1s = Int(Double(length) * 0.33)
        let b1e = Int(Double(length) * 0.48)
        let tps = Int(Double(length) * 0.58)
        let tpe = Int(Double(length) * 0.72)
        return [
            GeneMark(name: "BRCA1", start: b1s, end: b1e, type: GenomeFeatureType.gene, color: ColorPalette.geneBlue),
            GeneMark(name: "TP53",  start: tps, end: tpe, type: GenomeFeatureType.gene, color: ColorPalette.geneBlue)
        ]
    }
}


