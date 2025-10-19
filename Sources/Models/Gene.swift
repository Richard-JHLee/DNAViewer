//
//  Gene.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-18.
//

import Foundation

struct Gene: Identifiable, Codable, Hashable {
    let geneId: Int              // 유일 식별자
    let symbol: String           // 대표 이름 (예: TP53)
    let name: String             // 설명 (예: tumor protein p53)
    let organism: String         // 종 이름
    let taxId: Int               // NCBI Taxonomy ID
    let chromosome: String       // 위치 정보
    let geneType: String         // 기능적 분류
    let aliases: [String]        // 동의어
    let description: String?     // 요약 설명
    
    var id: Int { geneId }
    
    // Hashable implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(geneId)
    }
    
    static func == (lhs: Gene, rhs: Gene) -> Bool {
        return lhs.geneId == rhs.geneId
    }
}

// MARK: - Gene Categories

enum GeneCategory: String, CaseIterable {
    case organism = "Organism"
    case geneType = "Gene Type"
    case chromosome = "Chromosome"
    case status = "Status"
    case symbolPrefix = "Symbol Prefix"
    
    var koreanName: String {
        switch self {
        case .organism: return "종별"
        case .geneType: return "기능별"
        case .chromosome: return "염색체별"
        case .status: return "상태별"
        case .symbolPrefix: return "유전자 패밀리별"
        }
    }
}

enum GeneSubCategory: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }
    
    // Organism
    case homo_sapiens = "Homo sapiens"
    case mus_musculus = "Mus musculus"
    case drosophila_melanogaster = "Drosophila melanogaster"
    
    // Gene Type
    case protein_coding = "protein-coding"
    case miRNA = "miRNA"
    case lncRNA = "lncRNA"
    case pseudogene = "pseudogene"
    
    // Chromosome
    case chr1 = "1"
    case chr2 = "2"
    case chr3 = "3"
    case chr4 = "4"
    case chr5 = "5"
    case chr6 = "6"
    case chr7 = "7"
    case chr8 = "8"
    case chr9 = "9"
    case chr10 = "10"
    case chr11 = "11"
    case chr12 = "12"
    case chr13 = "13"
    case chr14 = "14"
    case chr15 = "15"
    case chr16 = "16"
    case chr17 = "17"
    case chr18 = "18"
    case chr19 = "19"
    case chr20 = "20"
    case chr21 = "21"
    case chr22 = "22"
    case chrX = "X"
    case chrY = "Y"
    case chrMT = "MT"
    
    // Status
    case live = "live"
    case discontinued = "discontinued"
    
    // Symbol Prefix
    case BRCA = "BRCA"
    case HBA = "HBA"
    case HBB = "HBB"
    case TP = "TP"
    case CFTR = "CFTR"
    case HTT = "HTT"
    
    var parentCategory: GeneCategory {
        switch self {
        case .homo_sapiens, .mus_musculus, .drosophila_melanogaster:
            return .organism
        case .protein_coding, .miRNA, .lncRNA, .pseudogene:
            return .geneType
        case .chr1, .chr2, .chr3, .chr4, .chr5, .chr6, .chr7, .chr8, .chr9, .chr10,
             .chr11, .chr12, .chr13, .chr14, .chr15, .chr16, .chr17, .chr18, .chr19, .chr20,
             .chr21, .chr22, .chrX, .chrY, .chrMT:
            return .chromosome
        case .live, .discontinued:
            return .status
        case .BRCA, .HBA, .HBB, .TP, .CFTR, .HTT:
            return .symbolPrefix
        }
    }
}

// MARK: - Sample Data

extension Gene {
    static let sampleGenes: [Gene] = [
        Gene(
            geneId: 7157,
            symbol: "TP53",
            name: "tumor protein p53",
            organism: "Homo sapiens",
            taxId: 9606,
            chromosome: "17",
            geneType: "protein-coding",
            aliases: ["P53", "TRP53", "p53"],
            description: "This gene encodes tumor protein p53, which responds to diverse cellular stresses to regulate target genes that induce cell cycle arrest, apoptosis, senescence, DNA repair, or changes in metabolism."
        ),
        Gene(
            geneId: 672,
            symbol: "BRCA1",
            name: "BRCA1 DNA repair associated",
            organism: "Homo sapiens",
            taxId: 9606,
            chromosome: "17",
            geneType: "protein-coding",
            aliases: ["BRCAI", "BRCC1"],
            description: "This gene encodes a 190 kD nuclear phosphoprotein that plays a role in maintaining genomic stability, and it also acts as a tumor suppressor."
        ),
        Gene(
            geneId: 675,
            symbol: "BRCA2",
            name: "BRCA2 DNA repair associated",
            organism: "Homo sapiens",
            taxId: 9606,
            chromosome: "13",
            geneType: "protein-coding",
            aliases: ["BRCC2", "FAD"],
            description: "This gene encodes a nuclear protein that is involved in the repair of chromosomal damage with an important role in the error-free repair of DNA double strand breaks."
        ),
        Gene(
            geneId: 1080,
            symbol: "CFTR",
            name: "CFTR transmembrane conductance regulator",
            organism: "Homo sapiens",
            taxId: 9606,
            chromosome: "7",
            geneType: "protein-coding",
            aliases: ["CF", "MRP7", "ABCC7"],
            description: "This gene encodes a member of the ATP-binding cassette (ABC) transporter superfamily. The protein functions as a chloride channel and controls the regulation of other transport pathways."
        ),
        Gene(
            geneId: 3064,
            symbol: "HTT",
            name: "huntingtin",
            organism: "Homo sapiens",
            taxId: 9606,
            chromosome: "4",
            geneType: "protein-coding",
            aliases: ["HD", "IT15"],
            description: "This gene encodes the huntingtin protein, which is essential for normal development and is involved in vesicle trafficking, clathrin-mediated endocytosis, autophagy, and postsynaptic signaling."
        ),
        Gene(
            geneId: 348,
            symbol: "APOE",
            name: "apolipoprotein E",
            organism: "Homo sapiens",
            taxId: 9606,
            chromosome: "19",
            geneType: "protein-coding",
            aliases: ["AD2"],
            description: "This gene encodes apolipoprotein E, which is a major apoprotein of chylomicrons and intermediate density lipoproteins."
        )
    ]
}
