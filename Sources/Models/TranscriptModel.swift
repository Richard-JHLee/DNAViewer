//
//  TranscriptModel.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-22.
//

import Foundation

struct TranscriptModel: Codable, Identifiable, Hashable {
    let id: String
    let display_name: String
    let start: Int
    let end: Int
    let strand: Int
    let biotype: String
    let exons: [ExonModel]
    let isCanonical: Bool
    let translation: TranslationModel?  // CDS information
    
    var length: Int {
        return end - start + 1
    }
    
    // Get 5' UTR region (before CDS)
    var utr5: (start: Int, end: Int)? {
        guard let translation = translation else { return nil }
        if strand >= 0 {
            // Forward strand: 5' UTR is before CDS
            return (start, translation.start - 1)
        } else {
            // Reverse strand: 5' UTR is after CDS
            return (translation.end + 1, end)
        }
    }
    
    // Get 3' UTR region (after CDS)
    var utr3: (start: Int, end: Int)? {
        guard let translation = translation else { return nil }
        if strand >= 0 {
            // Forward strand: 3' UTR is after CDS
            return (translation.end + 1, end)
        } else {
            // Reverse strand: 3' UTR is before CDS
            return (start, translation.start - 1)
        }
    }
}

// Translation (CDS) information
struct TranslationModel: Codable, Hashable {
    let id: String
    let start: Int  // CDS start position
    let end: Int    // CDS end position
    let length: Int // CDS length in nucleotides
}

struct ExonModel: Codable, Identifiable, Hashable {
    let id: String
    let start: Int
    let end: Int
    let strand: Int
    let rank: Int
    
    var length: Int {
        return end - start + 1
    }
    
    init(id: String, start: Int, end: Int, strand: Int, rank: Int) {
        self.id = id
        self.start = start
        self.end = end
        self.strand = strand
        self.rank = rank
    }
}

// MARK: - API Response Models
struct EnsemblTranscriptResponse: Codable {
    let id: String
    let display_name: String
    let start: Int
    let end: Int
    let strand: Int
    let biotype: String
    let Exon: [EnsemblExonResponse]?
    let is_canonical: Int?
    let Translation: EnsemblTranslationResponse?
    
    func toTranscriptModel() -> TranscriptModel {
        return TranscriptModel(
            id: id,
            display_name: display_name,
            start: start,
            end: end,
            strand: strand,
            biotype: biotype,
            exons: (Exon ?? []).map { $0.toExonModel() },
            isCanonical: (is_canonical ?? 0) == 1,
            translation: Translation?.toTranslationModel()
        )
    }
}

struct EnsemblTranslationResponse: Codable {
    let id: String
    let start: Int
    let end: Int
    let length: Int
    
    func toTranslationModel() -> TranslationModel {
        return TranslationModel(
            id: id,
            start: start,
            end: end,
            length: length
        )
    }
}

struct EnsemblExonResponse: Codable {
    let id: String
    let start: Int
    let end: Int
    let strand: Int
    let rank: Int?
    
    func toExonModel() -> ExonModel {
        return ExonModel(
            id: id,
            start: start,
            end: end,
            strand: strand,
            rank: rank ?? 0  // Default to 0 if rank is missing
        )
    }
}
