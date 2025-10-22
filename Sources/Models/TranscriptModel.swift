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
    
    var length: Int {
        return end - start + 1
    }
    
    var isCanonical: Bool {
        return biotype.contains("protein_coding")
    }
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
}

// MARK: - API Response Models
struct EnsemblTranscriptResponse: Codable {
    let id: String
    let display_name: String
    let start: Int
    let end: Int
    let strand: Int
    let biotype: String
    let Exon: [EnsemblExonResponse]
    
    func toTranscriptModel() -> TranscriptModel {
        return TranscriptModel(
            id: id,
            display_name: display_name,
            start: start,
            end: end,
            strand: strand,
            biotype: biotype,
            exons: Exon.map { $0.toExonModel() }
        )
    }
}

struct EnsemblExonResponse: Codable {
    let id: String
    let start: Int
    let end: Int
    let strand: Int
    let rank: Int
    
    func toExonModel() -> ExonModel {
        return ExonModel(
            id: id,
            start: start,
            end: end,
            strand: strand,
            rank: rank
        )
    }
}
