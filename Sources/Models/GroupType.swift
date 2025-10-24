//
//  GroupType.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-22.
//

import Foundation

enum GroupType: String, CaseIterable, Identifiable, Codable {
    case gene = "Gene"
    case transcript = "Transcript"
    case exon = "Exon"
    case region = "Region"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .gene: return "Gene"
        case .transcript: return "Transcript"
        case .exon: return "Exon"
        case .region: return "Region"
        }
    }
}

struct GroupMeta: Codable, Identifiable {
    var id = UUID()
    let type: GroupType
    let transcriptID: String?
    let exonIndex: Int?
    let regionStart: Int?
    let regionEnd: Int?
    
    init(type: GroupType, transcriptID: String? = nil, exonIndex: Int? = nil, regionStart: Int? = nil, regionEnd: Int? = nil) {
        self.type = type
        self.transcriptID = transcriptID
        self.exonIndex = exonIndex
        self.regionStart = regionStart
        self.regionEnd = regionEnd
    }
    
    var cacheKey: String {
        switch type {
        case .gene:
            return "gene:\(transcriptID ?? "")"
        case .transcript:
            return "tx:\(transcriptID ?? "")"
        case .exon:
            return "exon:\(transcriptID ?? ""):\(exonIndex ?? 0)"
        case .region:
            return "region:\(regionStart ?? 0)-\(regionEnd ?? 0)"
        }
    }
}
