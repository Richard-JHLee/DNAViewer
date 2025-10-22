//
//  SequenceProcessor.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-22.
//

import Foundation
import SwiftUI

class SequenceProcessor {
    static let shared = SequenceProcessor()
    
    private init() {}
    
    // MARK: - Sequence Processing
    func sliceSequence(_ sequence: String, length: Int = 20) -> String {
        let cleanSeq = sequence.replacingOccurrences(of: "\n", with: "")
        let maxLength = min(length, cleanSeq.count)
        return String(cleanSeq.prefix(maxLength))
    }
    
    func reverseComplement(_ sequence: String) -> String {
        let complement: [Character: Character] = [
            "A": "T", "T": "A",
            "G": "C", "C": "G",
            "N": "N"
        ]
        
        let reversed = String(sequence.reversed())
        return String(reversed.map { complement[$0] ?? $0 })
    }
    
    func processSequence(_ sequence: String, strand: Int, length: Int = 20) -> String {
        let cleanSeq = sequence.replacingOccurrences(of: "\n", with: "")
        
        if strand == 1 {
            // Positive strand: take first 20bp
            return sliceSequence(cleanSeq, length: length)
        } else {
            // Negative strand: take last 20bp and reverse complement
            let last20 = String(cleanSeq.suffix(length))
            return reverseComplement(last20)
        }
    }
    
    // MARK: - Color Mapping
    func getSequenceColor(_ base: Character) -> Color {
        switch base.uppercased().first {
        case "A": return .red
        case "T": return .blue
        case "G": return .green
        case "C": return .yellow
        default: return .gray
        }
    }
    
    func getSequenceColorName(_ base: Character) -> String {
        switch base.uppercased().first {
        case "A": return "Red"
        case "T": return "Blue"
        case "G": return "Green"
        case "C": return "Yellow"
        default: return "Gray"
        }
    }
    
    // MARK: - Validation
    func isValidSequence(_ sequence: String) -> Bool {
        let validBases = Set(["A", "T", "G", "C", "N"])
        let cleanSeq = sequence.replacingOccurrences(of: "\n", with: "").uppercased()
        return cleanSeq.allSatisfy { validBases.contains(String($0)) }
    }
    
    func isValidRegion(start: Int, end: Int, geneStart: Int, geneEnd: Int) -> Bool {
        return start >= geneStart && end <= geneEnd && start <= end
    }
}
