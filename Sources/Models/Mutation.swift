//
//  Mutation.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import Foundation
import SwiftUI

struct Mutation: Identifiable, Codable, Equatable {
    let id: UUID
    let position: Int
    let refBase: String    // Reference base
    let altBase: String    // Alternative base
    let type: MutationType
    let consequence: String // Missense, Nonsense, etc.
    let clinicalSignificance: ClinicalSignificance?
    let disease: String?
    let description: String?
    
    init(
        id: UUID = UUID(),
        position: Int,
        refBase: String,
        altBase: String,
        type: MutationType,
        consequence: String,
        clinicalSignificance: ClinicalSignificance? = nil,
        disease: String? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.position = position
        self.refBase = refBase
        self.altBase = altBase
        self.type = type
        self.consequence = consequence
        self.clinicalSignificance = clinicalSignificance
        self.disease = disease
        self.description = description
    }
    
    var displayNotation: String {
        return "c.\(position)\(refBase)>\(altBase)"
    }
    
    var severityColor: Color {
        return clinicalSignificance?.color ?? .gray
    }
}

enum MutationType: String, Codable, CaseIterable {
    case snp = "SNP"
    case insertion = "Insertion"
    case deletion = "Deletion"
    case inversion = "Inversion"
    case duplication = "Duplication"
    case substitution = "Substitution"
    
    var icon: String {
        switch self {
        case .snp: return "circle.fill"
        case .insertion: return "plus.circle.fill"
        case .deletion: return "minus.circle.fill"
        case .inversion: return "arrow.triangle.2.circlepath"
        case .duplication: return "doc.on.doc.fill"
        case .substitution: return "arrow.left.arrow.right"
        }
    }
}

enum ClinicalSignificance: String, Codable, CaseIterable {
    case pathogenic = "Pathogenic"
    case likelyPathogenic = "Likely Pathogenic"
    case benign = "Benign"
    case likelyBenign = "Likely Benign"
    case uncertain = "Uncertain Significance"
    
    var color: Color {
        switch self {
        case .pathogenic: return .red
        case .likelyPathogenic: return .orange
        case .benign: return .green
        case .likelyBenign: return .mint
        case .uncertain: return .yellow
        }
    }
}

