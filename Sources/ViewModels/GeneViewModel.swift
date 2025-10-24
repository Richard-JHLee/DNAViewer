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
        guard let gene = selectedGene else { 
            print("🔍 sequence20: No gene selected")
            return "" 
        }
        
        let meta = GroupMeta(
            type: selectedGroupType,
            transcriptID: selectedTranscriptID,
            exonIndex: selectedExonIndex,
            regionStart: regionStart,
            regionEnd: regionEnd
        )
        
        let cacheKey = meta.cacheKey
        print("🔍 sequence20: Looking for cacheKey: \(cacheKey)")
        print("🔍 sequence20: Available cache keys: \(sequenceCache.keys)")
        
        if let cachedSequence = sequenceCache[cacheKey] {
            let processed = SequenceProcessor.shared.processSequence(cachedSequence, strand: gene.strand)
            let result = String(processed.prefix(20))
            print("🔍 sequence20: Found cached sequence, length: \(cachedSequence.count), processed: \(processed.count), result: \(result.count)")
            print("🔍 sequence20: Result content: \(result)")
            return result
        }
        
        print("🔍 sequence20: No cached sequence found for key: \(cacheKey)")
        return ""
    }
    
    var fullSequence: String? {
        guard let gene = selectedGene else { return nil }
        
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
        
        return nil
    }
    
    var sequenceLength: Int {
        return fullSequence?.count ?? 0
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
    
    // Get detailed region information for a specific genomic range
    func getExonInfo(for range: Range<Int>) -> String {
        guard let gene = selectedGene else { return "Unknown region" }
        
        // Convert sequence positions to genomic coordinates
        let startGenomic = gene.start + range.lowerBound
        let endGenomic = gene.start + range.upperBound - 1
        
        // Check if in promoter region (upstream of gene)
        if startGenomic < gene.start {
            return "Promoter"
        }
        
        // Check if in downstream region
        if endGenomic > gene.end {
            return "Downstream"
        }
        
        // Check for CDS (Coding Sequence)
        if let transcript = transcripts.first(where: { $0.isCanonical }),
           let translation = transcript.translation {
            if startGenomic >= translation.start && endGenomic <= translation.end {
                // Check if in specific exon
                for exon in availableExons {
                    if startGenomic >= exon.start && endGenomic <= exon.end {
                        return "Exon \(exon.rank) (CDS)"
                    }
                }
                return "CDS"
            }
            
            // Check for 5' UTR
            if let utr5 = transcript.utr5 {
                if startGenomic >= utr5.start && endGenomic <= utr5.end {
                    return "5' UTR"
                }
            }
            
            // Check for 3' UTR
            if let utr3 = transcript.utr3 {
                if startGenomic >= utr3.start && endGenomic <= utr3.end {
                    return "3' UTR"
                }
            }
        }
        
        // Check for exons (non-coding)
        var overlappingExons: [ExonModel] = []
        for exon in availableExons {
            if startGenomic <= exon.end && endGenomic >= exon.start {
                overlappingExons.append(exon)
            }
        }
        
        if overlappingExons.isEmpty {
            return "Intron"
        } else if overlappingExons.count == 1 {
            let exon = overlappingExons[0]
            return "Exon \(exon.rank)"
        } else {
            let ranks = overlappingExons.map { String($0.rank) }.joined(separator: ", ")
            return "Exons \(ranks)"
        }
    }
    
    // Get detailed region information with description
    func getDetailedExonInfo(for range: Range<Int>) -> (region: String, details: String) {
        guard let gene = selectedGene else { return ("Unknown", "") }
        
        let startGenomic = gene.start + range.lowerBound
        let endGenomic = gene.start + range.upperBound - 1
        let rangeLength = range.upperBound - range.lowerBound
        
        // Check promoter
        if startGenomic < gene.start {
            return ("Promoter", "Regulatory region • \(rangeLength) bp")
        }
        
        // Check downstream
        if endGenomic > gene.end {
            return ("Downstream", "Post-gene region • \(rangeLength) bp")
        }
        
        // Check CDS and UTRs
        if let transcript = transcripts.first(where: { $0.isCanonical }),
           let translation = transcript.translation {
            
            // CDS region
            if startGenomic >= translation.start && endGenomic <= translation.end {
                for exon in availableExons {
                    if startGenomic >= exon.start && endGenomic <= exon.end {
                        return ("Exon \(exon.rank) (CDS)", "Protein coding • \(rangeLength) bp")
                    }
                }
                return ("CDS", "Coding sequence • \(rangeLength) bp")
            }
            
            // 5' UTR
            if let utr5 = transcript.utr5 {
                if startGenomic >= utr5.start && endGenomic <= utr5.end {
                    return ("5' UTR", "Untranslated region (5' end) • \(rangeLength) bp")
                }
            }
            
            // 3' UTR
            if let utr3 = transcript.utr3 {
                if startGenomic >= utr3.start && endGenomic <= utr3.end {
                    return ("3' UTR", "Untranslated region (3' end) • \(rangeLength) bp")
                }
            }
        }
        
        // Check exons
        var overlappingExons: [ExonModel] = []
        for exon in availableExons {
            if startGenomic <= exon.end && endGenomic >= exon.start {
                overlappingExons.append(exon)
            }
        }
        
        if overlappingExons.isEmpty {
            return ("Intron", "Non-coding region between exons • \(rangeLength) bp")
        } else if overlappingExons.count == 1 {
            let exon = overlappingExons[0]
            return ("Exon \(exon.rank)", "Genomic: \(exon.start)-\(exon.end) • \(exon.length) bp")
        } else {
            let ranks = overlappingExons.map { String($0.rank) }.joined(separator: ", ")
            return ("Exons \(ranks)", "Spanning multiple exons • \(rangeLength) bp")
        }
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
            print("🔍 Step 1: Looking up gene \(symbol)...")
            let gene = try await apiService.lookupSymbol(symbol)
            selectedGene = gene
            print("✅ Gene found: \(gene.display_name)")
            
            // Small delay to avoid rate limiting
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Load neighboring genes (with error handling)
            print("🔍 Step 2: Loading neighboring genes...")
            do {
                let neighbors = try await apiService.getNeighboringGenes(for: gene)
                neighboringGenes = neighbors
                print("✅ Found \(neighbors.count) neighboring genes")
            } catch {
                print("⚠️ Failed to load neighboring genes, using empty list: \(error)")
                neighboringGenes = []
            }
            
            // Small delay
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Load transcripts (with error handling)
            print("🔍 Step 3: Loading transcripts...")
            do {
                let transcriptList = try await apiService.getTranscripts(for: gene)
                transcripts = transcriptList
                print("✅ Found \(transcriptList.count) transcripts")
                
                // Set default transcript (prefer canonical, then first protein_coding, then first)
                if let canonicalTranscript = transcriptList.first(where: { $0.isCanonical }) {
                    selectedTranscriptID = canonicalTranscript.id
                    print("✅ Selected canonical transcript: \(canonicalTranscript.display_name) (\(canonicalTranscript.id))")
                } else if let proteinCoding = transcriptList.first(where: { $0.biotype == "protein_coding" }) {
                    selectedTranscriptID = proteinCoding.id
                    print("✅ Selected first protein_coding transcript: \(proteinCoding.display_name) (\(proteinCoding.id))")
                } else if let firstTranscript = transcriptList.first {
                    selectedTranscriptID = firstTranscript.id
                    print("✅ Selected first transcript: \(firstTranscript.display_name) (\(firstTranscript.id))")
                } else {
                    print("⚠️ No transcripts available")
                }
                
                // Set default exon (first exon of selected transcript)
                if let transcriptID = selectedTranscriptID,
                   let transcript = transcriptList.first(where: { $0.id == transcriptID }),
                   let firstExon = transcript.exons.first {
                    selectedExonIndex = 0
                    print("✅ Selected first exon: \(firstExon.id)")
                }
                
                // Set default region (gene boundaries)
                if let gene = selectedGene {
                    regionStart = gene.start
                    regionEnd = gene.end
                    print("✅ Set default region: \(gene.start)-\(gene.end)")
                }
            } catch {
                print("⚠️ Failed to load transcripts, using empty list: \(error)")
                transcripts = []
            }
            
                // Small delay
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Load initial sequence for Gene type only
                print("🔍 Step 4: Loading initial sequence for Gene...")
                if selectedGroupType == .gene {
                    await loadSequence()
                }
            
        } catch {
            print("❌ Failed to search gene: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
        print("✅ Gene search complete")
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
        guard let gene = selectedGene else {
            print("⚠️ No gene selected, skipping sequence load")
            return
        }
        
        let meta = GroupMeta(
            type: selectedGroupType,
            transcriptID: selectedTranscriptID,
            exonIndex: selectedExonIndex,
            regionStart: regionStart,
            regionEnd: regionEnd
        )
        
        let cacheKey = meta.cacheKey
        
        // Check cache first
        if let cachedSeq = sequenceCache[cacheKey] {
            print("✅ Using cached sequence: \(cachedSeq.prefix(20))... (\(cachedSeq.count) bp)")
            return
        }
        
        print("🔍 Loading sequence for \(selectedGroupType.displayName)...")
        print("🔍 Meta parameters: transcriptID=\(selectedTranscriptID ?? "nil"), exonIndex=\(selectedExonIndex ?? -1), regionStart=\(regionStart ?? -1), regionEnd=\(regionEnd ?? -1)")
        
        do {
            let sequence = try await apiService.getSequence(for: gene, type: selectedGroupType, meta: meta)
            sequenceCache[cacheKey] = sequence
            print("✅ Sequence loaded and cached: \(sequence.prefix(20))... (\(sequence.count) bp)")
        } catch {
            print("❌ Failed to load sequence: \(error.localizedDescription)")
            print("🚫 No fallback data - showing error to user")
            
            // Don't use fallback sequence - let the UI show error state
            // This ensures users know when data loading failed
        }
    }
    
    func clearCache() {
        sequenceCache.removeAll()
    }
    
    func clearError() {
        errorMessage = nil
    }
}
