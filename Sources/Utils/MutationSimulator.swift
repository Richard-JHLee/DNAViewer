//
//  MutationSimulator.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import Foundation

class MutationSimulator {
    
    enum MutationResult {
        case synonymous      // Same amino acid
        case missense       // Different amino acid
        case nonsense       // Stop codon introduced
        case frameshift     // Reading frame changed
        case noChange       // No effect
        
        var description: String {
            switch self {
            case .synonymous: return "Synonymous (silent mutation)"
            case .missense: return "Missense (amino acid change)"
            case .nonsense: return "Nonsense (premature stop)"
            case .frameshift: return "Frameshift (reading frame shift)"
            case .noChange: return "No effect"
            }
        }
    }
    
    struct MutationEffect {
        let originalSequence: String
        let mutatedSequence: String
        let originalProtein: String?
        let mutatedProtein: String?
        let mutationType: MutationType
        let result: MutationResult
        let position: Int
        let description: String
    }
    
    // MARK: - Point Mutation (SNP)
    
    static func applyPointMutation(sequence: String, position: Int, newBase: String) -> MutationEffect {
        guard position >= 0 && position < sequence.count else {
            return MutationEffect(
                originalSequence: sequence,
                mutatedSequence: sequence,
                originalProtein: nil,
                mutatedProtein: nil,
                mutationType: .snp,
                result: .noChange,
                position: position,
                description: "Invalid position"
            )
        }
        
        var mutated = sequence
        let index = mutated.index(mutated.startIndex, offsetBy: position)
        let originalBase = String(mutated[index])
        mutated.replaceSubrange(index...index, with: newBase)
        
        // Translate to check effect
        let originalProtein = translateSequence(sequence, startingFrom: position)
        let mutatedProtein = translateSequence(mutated, startingFrom: position)
        
        let result = compareProteins(original: originalProtein, mutated: mutatedProtein)
        
        return MutationEffect(
            originalSequence: sequence,
            mutatedSequence: mutated,
            originalProtein: originalProtein,
            mutatedProtein: mutatedProtein,
            mutationType: .snp,
            result: result,
            position: position,
            description: "\(originalBase) → \(newBase) at position \(position)"
        )
    }
    
    // MARK: - Insertion
    
    static func applyInsertion(sequence: String, position: Int, insertedBases: String) -> MutationEffect {
        guard position >= 0 && position <= sequence.count else {
            return MutationEffect(
                originalSequence: sequence,
                mutatedSequence: sequence,
                originalProtein: nil,
                mutatedProtein: nil,
                mutationType: .insertion,
                result: .noChange,
                position: position,
                description: "Invalid position"
            )
        }
        
        var mutated = sequence
        let index = mutated.index(mutated.startIndex, offsetBy: position)
        mutated.insert(contentsOf: insertedBases, at: index)
        
        let originalProtein = translateSequence(sequence, startingFrom: position)
        let mutatedProtein = translateSequence(mutated, startingFrom: position)
        
        // Insertion causes frameshift unless length is multiple of 3
        let result: MutationResult = (insertedBases.count % 3 == 0) ?
            compareProteins(original: originalProtein, mutated: mutatedProtein) : .frameshift
        
        return MutationEffect(
            originalSequence: sequence,
            mutatedSequence: mutated,
            originalProtein: originalProtein,
            mutatedProtein: mutatedProtein,
            mutationType: .insertion,
            result: result,
            position: position,
            description: "Inserted \(insertedBases) at position \(position)"
        )
    }
    
    // MARK: - Deletion
    
    static func applyDeletion(sequence: String, position: Int, length: Int) -> MutationEffect {
        guard position >= 0 && position + length <= sequence.count else {
            return MutationEffect(
                originalSequence: sequence,
                mutatedSequence: sequence,
                originalProtein: nil,
                mutatedProtein: nil,
                mutationType: .deletion,
                result: .noChange,
                position: position,
                description: "Invalid position or length"
            )
        }
        
        var mutated = sequence
        let startIndex = mutated.index(mutated.startIndex, offsetBy: position)
        let endIndex = mutated.index(startIndex, offsetBy: length)
        let deletedBases = String(mutated[startIndex..<endIndex])
        mutated.removeSubrange(startIndex..<endIndex)
        
        let originalProtein = translateSequence(sequence, startingFrom: position)
        let mutatedProtein = translateSequence(mutated, startingFrom: position)
        
        // Deletion causes frameshift unless length is multiple of 3
        let result: MutationResult = (length % 3 == 0) ?
            compareProteins(original: originalProtein, mutated: mutatedProtein) : .frameshift
        
        return MutationEffect(
            originalSequence: sequence,
            mutatedSequence: mutated,
            originalProtein: originalProtein,
            mutatedProtein: mutatedProtein,
            mutationType: .deletion,
            result: result,
            position: position,
            description: "Deleted \(deletedBases) at position \(position)"
        )
    }
    
    // MARK: - Inversion
    
    static func applyInversion(sequence: String, startPosition: Int, endPosition: Int) -> MutationEffect {
        guard startPosition >= 0 && endPosition < sequence.count && startPosition < endPosition else {
            return MutationEffect(
                originalSequence: sequence,
                mutatedSequence: sequence,
                originalProtein: nil,
                mutatedProtein: nil,
                mutationType: .inversion,
                result: .noChange,
                position: startPosition,
                description: "Invalid positions"
            )
        }
        
        var mutated = sequence
        let startIndex = mutated.index(mutated.startIndex, offsetBy: startPosition)
        let endIndex = mutated.index(mutated.startIndex, offsetBy: endPosition + 1)
        let inverted = String(mutated[startIndex..<endIndex].reversed())
        mutated.replaceSubrange(startIndex..<endIndex, with: inverted)
        
        let originalProtein = translateSequence(sequence, startingFrom: startPosition)
        let mutatedProtein = translateSequence(mutated, startingFrom: startPosition)
        
        let result = compareProteins(original: originalProtein, mutated: mutatedProtein)
        
        return MutationEffect(
            originalSequence: sequence,
            mutatedSequence: mutated,
            originalProtein: originalProtein,
            mutatedProtein: mutatedProtein,
            mutationType: .inversion,
            result: result,
            position: startPosition,
            description: "Inverted bases from \(startPosition) to \(endPosition)"
        )
    }
    
    // MARK: - Helper Functions
    
    private static func translateSequence(_ sequence: String, startingFrom position: Int) -> String {
        // Find the reading frame that contains this position
        let frameStart = (position / 3) * 3
        
        guard frameStart < sequence.count else {
            return ""
        }
        
        let startIndex = sequence.index(sequence.startIndex, offsetBy: frameStart)
        let frameSequence = String(sequence[startIndex...])
        
        let codons = CodonTable.shared.translateSequence(frameSequence)
        return codons.map { $0.aminoAcid }.joined()
    }
    
    private static func compareProteins(original: String, mutated: String) -> MutationResult {
        guard !original.isEmpty && !mutated.isEmpty else {
            return .noChange
        }
        
        // Check for stop codon
        if mutated.contains("*") && !original.contains("*") {
            return .nonsense
        }
        
        // Compare amino acid sequences
        if original == mutated {
            return .synonymous
        } else {
            return .missense
        }
    }
}

