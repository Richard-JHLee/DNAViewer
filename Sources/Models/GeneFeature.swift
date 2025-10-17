//
//  GeneFeature.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import Foundation
import SwiftUI

struct GeneFeature: Identifiable, Codable, Equatable {
    let id: UUID
    let type: FeatureType
    let startIndex: Int  // 서열 내 시작 위치
    let endIndex: Int    // 서열 내 종료 위치
    let label: String?
    let description: String?
    
    init(
        id: UUID = UUID(),
        type: FeatureType,
        startIndex: Int,
        endIndex: Int,
        label: String? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.type = type
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.label = label
        self.description = description
    }
    
    var length: Int {
        return endIndex - startIndex + 1
    }
    
    var displayColor: Color {
        return type.color
    }
}

enum FeatureType: String, Codable, CaseIterable {
    case promoter = "Promoter"
    case exon = "Exon"
    case intron = "Intron"
    case utr5 = "5' UTR"
    case utr3 = "3' UTR"
    case cds = "CDS"
    case polyA = "Poly-A"
    case enhancer = "Enhancer"
    case silencer = "Silencer"
    
    var color: Color {
        switch self {
        case .promoter: return .purple
        case .exon: return .green
        case .intron: return .gray
        case .utr5: return .orange
        case .utr3: return .orange
        case .cds: return .blue
        case .polyA: return .pink
        case .enhancer: return .yellow
        case .silencer: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .promoter: return "arrow.forward.circle"
        case .exon: return "square.fill"
        case .intron: return "minus"
        case .utr5: return "chevron.left"
        case .utr3: return "chevron.right"
        case .cds: return "circle.fill"
        case .polyA: return "a.circle"
        case .enhancer: return "plus.circle"
        case .silencer: return "x.circle"
        }
    }
}

