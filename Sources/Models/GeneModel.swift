//
//  GeneModel.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-22.
//

import Foundation

struct GeneModel: Codable, Identifiable, Hashable {
    let id: String
    let display_name: String
    let seq_region_name: String
    let start: Int
    let end: Int
    let strand: Int
    
    var chromosome: String {
        return seq_region_name
    }
    
    var length: Int {
        return end - start + 1
    }
    
    var midpoint: Int {
        return (start + end) / 2
    }
    
    var isBRCA1: Bool {
        return display_name.uppercased() == "BRCA1"
    }
}

// MARK: - API Response Models
struct EnsemblLookupResponse: Codable {
    let id: String
    let display_name: String
    let seq_region_name: String
    let start: Int
    let end: Int
    let strand: Int
    let object_type: String
    let biotype: String
    let description: String?
    
    func toGeneModel() -> GeneModel {
        return GeneModel(
            id: id,
            display_name: display_name,
            seq_region_name: seq_region_name,
            start: start,
            end: end,
            strand: strand
        )
    }
}

struct EnsemblOverlapResponse: Codable {
    let id: String
    let external_name: String?
    let display_name: String?
    let seq_region_name: String
    let start: Int
    let end: Int
    let strand: Int
    let feature_type: String // Changed from object_type to feature_type
    let biotype: String
    
    func toGeneModel() -> GeneModel {
        let name = external_name ?? display_name ?? id // Prioritize external_name first
        return GeneModel(
            id: id,
            display_name: name,
            seq_region_name: seq_region_name,
            start: start,
            end: end,
            strand: strand
        )
    }
}
