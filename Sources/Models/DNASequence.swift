//
//  DNASequence.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import Foundation

struct DNASequence: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String           // 유전자명 또는 설명
    let accession: String?     // GenBank Accession
    let pdbID: String?         // PDB ID (구조 데이터)
    let sequence: String       // 염기서열 (ATGC)
    let chromosome: String?    // 염색체 위치
    let startPos: Int?
    let endPos: Int?
    let strand: Strand         // Plus(+) / Minus(-)
    let geneType: GeneType     // Coding / NonCoding / Regulatory
    let organism: String       // Homo sapiens, etc.
    var features: [GeneFeature] // Exon, Intron, Promoter 등
    var mutations: [Mutation]   // 알려진 돌연변이
    let summary: String?        // 기능 요약
    let diseaseLinks: [String]? // 관련 질병
    
    init(
        id: UUID = UUID(),
        name: String,
        accession: String? = nil,
        pdbID: String? = nil,
        sequence: String,
        chromosome: String? = nil,
        startPos: Int? = nil,
        endPos: Int? = nil,
        strand: Strand = .plus,
        geneType: GeneType = .coding,
        organism: String = "Homo sapiens",
        features: [GeneFeature] = [],
        mutations: [Mutation] = [],
        summary: String? = nil,
        diseaseLinks: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.accession = accession
        self.pdbID = pdbID
        self.sequence = sequence
        self.chromosome = chromosome
        self.startPos = startPos
        self.endPos = endPos
        self.strand = strand
        self.geneType = geneType
        self.organism = organism
        self.features = features
        self.mutations = mutations
        self.summary = summary
        self.diseaseLinks = diseaseLinks
    }
    
    // Computed properties
    var length: Int {
        return sequence.count
    }
    
    var gcContent: Double {
        let gcCount = sequence.filter { $0 == "G" || $0 == "C" }.count
        return Double(gcCount) / Double(sequence.count) * 100.0
    }
    
    var complementaryStrand: String {
        return sequence.map { base in
            switch base {
            case "A": return "T"
            case "T": return "A"
            case "G": return "C"
            case "C": return "G"
            default: return base
            }
        }.map { String($0) }.joined()
    }
    
    var reverseComplement: String {
        return String(complementaryStrand.reversed())
    }
}

enum Strand: String, Codable, CaseIterable {
    case plus = "+"
    case minus = "-"
}

enum GeneType: String, Codable, CaseIterable {
    case coding = "Coding"
    case nonCoding = "Non-Coding"
    case regulatory = "Regulatory"
    case intergenic = "Intergenic"
}

