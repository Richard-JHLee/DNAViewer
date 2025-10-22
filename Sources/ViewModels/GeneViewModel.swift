//
//  GeneViewModel.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-22.
//

import Foundation
import SwiftUI

@MainActor
class GeneViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchQuery: String = ""
    @Published var selectedGene: GeneModel?
    @Published var neighboringGenes: [GeneModel] = []
    @Published var selectedGroupType: GroupType = .gene
    @Published var selectedTranscriptID: String?
    @Published var selectedExonIndex: Int?
    @Published var regionStart: Int?
    @Published var regionEnd: Int?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var transcripts: [TranscriptModel] = []
    
    // MARK: - Computed Properties
    var sequence20: String {
        guard let gene = selectedGene else { return "" }
        
        let meta = GroupMeta(
            type: selectedGroupType,
            transcriptID: selectedTranscriptID,
            exonIndex: selectedExonIndex,
            regionStart: regionStart,
            regionEnd: regionEnd
        )
        
        let cacheKey = meta.cacheKey
        if let cachedSequence = sequenceCache[cacheKey] {
            return SequenceProcessor.shared.processSequence(cachedSequence, strand: gene.strand)
        }
        
        return ""
    }
    
    var sequenceLength: Int {
        return sequence20.count
    }
    
    var displayTitle: String {
        if let gene = selectedGene {
            return "\(gene.display_name) (\(gene.chromosome))"
        }
        return "Genome Map"
    }
    
    var availableTranscripts: [TranscriptModel] {
        return transcripts.filter { $0.isCanonical }
    }
    
    var availableExons: [ExonModel] {
        guard let transcriptID = selectedTranscriptID,
              let transcript = transcripts.first(where: { $0.id == transcriptID }) else {
            return []
        }
        return transcript.exons.sorted { $0.rank < $1.rank }
    }
    
    // MARK: - Private Properties
    private var sequenceCache: [String: String] = [:]
    private let apiService = EnsemblAPIService.shared
    private let processor = SequenceProcessor.shared
    
    // MARK: - Public Methods
    func searchGene(_ symbol: String) async {
        guard !symbol.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let gene = try await apiService.lookupSymbol(symbol)
            selectedGene = gene
            
            // Load neighboring genes
            let neighbors = try await apiService.getNeighboringGenes(for: gene)
            neighboringGenes = neighbors
            
            // Load transcripts
            let transcriptList = try await apiService.getTranscripts(for: gene)
            transcripts = transcriptList
            
            // Set default transcript
            if let canonicalTranscript = transcriptList.first(where: { $0.isCanonical }) {
                selectedTranscriptID = canonicalTranscript.id
            }
            
            // Load initial sequence
            await loadSequence()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func selectGene(_ gene: GeneModel) async {
        selectedGene = gene
        await loadSequence()
    }
    
    func changeGroupType(_ type: GroupType) async {
        selectedGroupType = type
        
        // Reset dependent selections
        switch type {
        case .gene:
            selectedTranscriptID = nil
            selectedExonIndex = nil
            regionStart = nil
            regionEnd = nil
        case .transcript:
            selectedExonIndex = nil
            regionStart = nil
            regionEnd = nil
        case .exon:
            regionStart = nil
            regionEnd = nil
        case .region:
            selectedExonIndex = nil
        }
        
        await loadSequence()
    }
    
    func selectTranscript(_ transcriptID: String) async {
        selectedTranscriptID = transcriptID
        selectedExonIndex = nil
        await loadSequence()
    }
    
    func selectExon(_ exonIndex: Int) async {
        selectedExonIndex = exonIndex
        await loadSequence()
    }
    
    func setRegion(start: Int, end: Int) async {
        regionStart = start
        regionEnd = end
        await loadSequence()
    }
    
    // MARK: - Private Methods
    private func loadSequence() async {
        guard let gene = selectedGene else { return }
        
        let meta = GroupMeta(
            type: selectedGroupType,
            transcriptID: selectedTranscriptID,
            exonIndex: selectedExonIndex,
            regionStart: regionStart,
            regionEnd: regionEnd
        )
        
        let cacheKey = meta.cacheKey
        
        // Check cache first
        if sequenceCache[cacheKey] != nil {
            return
        }
        
        do {
            let sequence = try await apiService.getSequence(for: gene, type: selectedGroupType, meta: meta)
            sequenceCache[cacheKey] = sequence
        } catch {
            errorMessage = "Failed to load sequence: \(error.localizedDescription)"
        }
    }
    
    func clearCache() {
        sequenceCache.removeAll()
    }
    
    func clearError() {
        errorMessage = nil
    }
}
