//
//  DNAFragment.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-18.
//

import Foundation

struct DNAFragment {
    let sequence: String
    let start: Int
    let end: Int
    let length: Int
    
    init(sequence: String, start: Int, end: Int) {
        self.sequence = sequence
        self.start = start
        self.end = end
        self.length = end - start
    }
    
    // Computed properties
    var gcContent: Double {
        let gcCount = sequence.uppercased().filter { $0 == "G" || $0 == "C" }.count
        return Double(gcCount) / Double(sequence.count) * 100
    }
    
    var meltingTemperature: Double {
        // Simple approximation for melting temperature
        let gcCount = sequence.uppercased().filter { $0 == "G" || $0 == "C" }.count
        let atCount = sequence.count - gcCount
        return 4 * Double(gcCount) + 2 * Double(atCount)
    }
    
    var complement: String {
        return sequence.map { base in
            switch base.uppercased().first {
            case "A": return "T"
            case "T": return "A"
            case "G": return "C"
            case "C": return "G"
            default: return String(base)
            }
        }.joined()
    }
    
    var reverseComplement: String {
        return String(complement.reversed())
    }
}
