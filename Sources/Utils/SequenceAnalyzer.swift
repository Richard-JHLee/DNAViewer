//
//  SequenceAnalyzer.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import Foundation

class SequenceAnalyzer {
    
    // MARK: - GC Content Analysis
    
    static func calculateGCContent(_ sequence: String) -> Double {
        let gcCount = sequence.filter { $0 == "G" || $0 == "C" }.count
        return Double(gcCount) / Double(sequence.count) * 100.0
    }
    
    static func calculateGCContentWindow(_ sequence: String, windowSize: Int = 100) -> [(position: Int, gcContent: Double)] {
        var results: [(Int, Double)] = []
        
        guard sequence.count >= windowSize else {
            return [(0, calculateGCContent(sequence))]
        }
        
        for i in stride(from: 0, to: sequence.count - windowSize + 1, by: windowSize / 2) {
            let startIndex = sequence.index(sequence.startIndex, offsetBy: i)
            let endIndex = sequence.index(startIndex, offsetBy: windowSize, limitedBy: sequence.endIndex) ?? sequence.endIndex
            let window = String(sequence[startIndex..<endIndex])
            let gcContent = calculateGCContent(window)
            results.append((i, gcContent))
        }
        
        return results
    }
    
    // MARK: - ORF (Open Reading Frame) Finding
    
    struct ORF {
        let frame: Int           // 0, 1, 2 for forward; -1, -2, -3 for reverse
        let startPosition: Int
        let endPosition: Int
        let sequence: String
        let proteinSequence: String
        
        var length: Int {
            return endPosition - startPosition + 1
        }
    }
    
    static func findORFs(_ sequence: String, minLength: Int = 75) -> [ORF] {
        var orfs: [ORF] = []
        let startCodon = "ATG"
        let stopCodons = ["TAA", "TAG", "TGA"]
        
        // Search in all 6 frames (3 forward, 3 reverse)
        for frame in 0..<3 {
            // Forward strand
            orfs.append(contentsOf: findORFsInFrame(sequence, frame: frame, minLength: minLength))
            
            // Reverse complement
            let reverseSeq = reverseComplement(sequence)
            orfs.append(contentsOf: findORFsInFrame(reverseSeq, frame: -(frame + 1), minLength: minLength))
        }
        
        return orfs.sorted { $0.length > $1.length }
    }
    
    private static func findORFsInFrame(_ sequence: String, frame: Int, minLength: Int) -> [ORF] {
        var orfs: [ORF] = []
        let frameOffset = abs(frame) - (frame < 0 ? 1 : 0)
        
        var i = frameOffset
        var inORF = false
        var orfStart = 0
        
        while i <= sequence.count - 3 {
            let startIndex = sequence.index(sequence.startIndex, offsetBy: i)
            let endIndex = sequence.index(startIndex, offsetBy: 3)
            let codon = String(sequence[startIndex..<endIndex])
            
            if codon == "ATG" && !inORF {
                inORF = true
                orfStart = i
            } else if ["TAA", "TAG", "TGA"].contains(codon) && inORF {
                let length = i - orfStart + 3
                if length >= minLength {
                    let orfStartIndex = sequence.index(sequence.startIndex, offsetBy: orfStart)
                    let orfEndIndex = sequence.index(sequence.startIndex, offsetBy: i + 3)
                    let orfSequence = String(sequence[orfStartIndex..<orfEndIndex])
                    let proteinSeq = translateToProtein(orfSequence)
                    
                    orfs.append(ORF(
                        frame: frame,
                        startPosition: orfStart,
                        endPosition: i + 2,
                        sequence: orfSequence,
                        proteinSequence: proteinSeq
                    ))
                }
                inORF = false
            }
            
            i += 3
        }
        
        return orfs
    }
    
    // MARK: - CpG Island Finding
    
    struct CpGIsland {
        let startPosition: Int
        let endPosition: Int
        let gcContent: Double
        let cpgRatio: Double
        
        var length: Int {
            return endPosition - startPosition + 1
        }
    }
    
    static func findCpGIslands(_ sequence: String, windowSize: Int = 200, minGC: Double = 50.0, minCpG: Double = 0.6) -> [CpGIsland] {
        var islands: [CpGIsland] = []
        
        for i in stride(from: 0, to: sequence.count - windowSize + 1, by: 10) {
            let startIndex = sequence.index(sequence.startIndex, offsetBy: i)
            let endIndex = sequence.index(startIndex, offsetBy: windowSize, limitedBy: sequence.endIndex) ?? sequence.endIndex
            let window = String(sequence[startIndex..<endIndex])
            
            let gcContent = calculateGCContent(window)
            let cpgRatio = calculateObservedExpectedCpG(window)
            
            if gcContent >= minGC && cpgRatio >= minCpG {
                islands.append(CpGIsland(
                    startPosition: i,
                    endPosition: i + windowSize - 1,
                    gcContent: gcContent,
                    cpgRatio: cpgRatio
                ))
            }
        }
        
        // Merge overlapping islands
        return mergeOverlappingIslands(islands)
    }
    
    private static func calculateObservedExpectedCpG(_ sequence: String) -> Double {
        let cCount = Double(sequence.filter { $0 == "C" }.count)
        let gCount = Double(sequence.filter { $0 == "G" }.count)
        let cpgCount = Double(countOccurrences(of: "CG", in: sequence))
        let length = Double(sequence.count)
        
        guard cCount > 0 && gCount > 0 && length > 0 else {
            return 0.0
        }
        
        let expected = (cCount * gCount) / length
        return expected > 0 ? cpgCount / expected : 0.0
    }
    
    private static func mergeOverlappingIslands(_ islands: [CpGIsland]) -> [CpGIsland] {
        guard !islands.isEmpty else { return [] }
        
        var merged: [CpGIsland] = []
        var current = islands[0]
        
        for i in 1..<islands.count {
            let next = islands[i]
            if current.endPosition >= next.startPosition {
                // Merge
                current = CpGIsland(
                    startPosition: current.startPosition,
                    endPosition: max(current.endPosition, next.endPosition),
                    gcContent: (current.gcContent + next.gcContent) / 2,
                    cpgRatio: (current.cpgRatio + next.cpgRatio) / 2
                )
            } else {
                merged.append(current)
                current = next
            }
        }
        merged.append(current)
        
        return merged
    }
    
    // MARK: - Helper Functions
    
    static func reverseComplement(_ sequence: String) -> String {
        let complement = sequence.map { base -> Character in
            switch base {
            case "A": return "T"
            case "T": return "A"
            case "G": return "C"
            case "C": return "G"
            default: return base
            }
        }
        return String(complement.reversed())
    }
    
    static func translateToProtein(_ sequence: String) -> String {
        let codons = CodonTable.shared.translateSequence(sequence)
        return codons.map { $0.aminoAcid }.joined()
    }
    
    static func countOccurrences(of pattern: String, in text: String) -> Int {
        var count = 0
        var searchRange = text.startIndex..<text.endIndex
        
        while let range = text.range(of: pattern, range: searchRange) {
            count += 1
            searchRange = range.upperBound..<text.endIndex
        }
        
        return count
    }
    
    // MARK: - Base Composition
    
    static func getBaseComposition(_ sequence: String) -> [Character: Int] {
        var composition: [Character: Int] = ["A": 0, "T": 0, "G": 0, "C": 0, "N": 0]
        
        for base in sequence {
            if let count = composition[base] {
                composition[base] = count + 1
            }
        }
        
        return composition
    }
}

