//
//  GenomeMapView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-22.
//

import SwiftUI

struct GenomeMapView: View {
    @StateObject private var viewModel = GeneViewModel()
    let currentSequence: DNASequence?
    @ObservedObject var sceneManager: DNASceneManager
    
    // Current group information
    private var currentGroupInfo: String {
        let groupNum = sceneManager.currentGroup
        let totalGroups = sceneManager.totalGroups
        return "Group \(groupNum) of \(totalGroups)"
    }
    
    private var currentGroupExonInfo: String {
        // Calculate current group's sequence range
        let start = sceneManager.displayStart
        let length = sceneManager.displayLength
        let end = start + length
        let range = start..<end
        
        // Get exon information for this range
        return viewModel.getExonInfo(for: range)
    }
    
    private var currentGroupDetails: String {
        let start = sceneManager.displayStart
        let length = sceneManager.displayLength
        let end = start + length
        
        return "Position: \(start)-\(end-1) bp (\(length) bp)"
    }
    
    // Color coding for different genomic regions
    private func getBadgeColor(for regionType: String) -> Color {
        if regionType.contains("CDS") || regionType.contains("Coding") {
            return Color.blue  // Coding sequence - blue
        } else if regionType.contains("5' UTR") {
            return Color.purple  // 5' UTR - purple
        } else if regionType.contains("3' UTR") {
            return Color.indigo  // 3' UTR - indigo
        } else if regionType.contains("Exon") {
            return Color.green  // Exon - green
        } else if regionType.contains("Intron") {
            return Color.orange  // Intron - orange
        } else if regionType.contains("Promoter") {
            return Color.pink  // Promoter - pink
        } else if regionType.contains("Downstream") {
            return Color.brown  // Downstream - brown
        } else {
            return Color.gray  // Unknown - gray
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Content
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else if viewModel.selectedGene != nil {
                mainContentView
            } else {
                emptyStateView
            }
        }
        .navigationTitle(viewModel.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Load gene based on current sequence
            if let sequence = currentSequence {
                // Extract gene symbol from sequence name
                let geneSymbol = extractGeneSymbol(from: sequence.name)
                await viewModel.searchGene(geneSymbol)
            } else {
                // Default to BRCA1 if no sequence provided
                await viewModel.searchGene("BRCA1")
            }
        }
        .onChange(of: currentSequence?.name) { newName in
            // Reload gene when sequence changes
            if let newName = newName {
                let geneSymbol = extractGeneSymbol(from: newName)
                Task {
                    await viewModel.searchGene(geneSymbol)
                }
            }
        }
    }
    
    // Extract gene symbol from sequence name
    private func extractGeneSymbol(from name: String) -> String {
        // Try to extract gene symbol (e.g., "BRCA1 (Breast Cancer Gene 1)" -> "BRCA1")
        if let openParen = name.firstIndex(of: "(") {
            let beforeParen = name[..<openParen].trimmingCharacters(in: .whitespaces)
            return beforeParen
        }
        
        // Try to extract before dash
        if let dashIndex = name.firstIndex(of: "-") {
            let beforeDash = name[..<dashIndex].trimmingCharacters(in: .whitespaces)
            return beforeDash
        }
        
        // Return as is
        return name.trimmingCharacters(in: .whitespaces)
    }
    
    // MARK: - Main Content
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Chromosome Ideogram (Image) - At the top
                ChromosomeIdeogramView(
                    selectedGene: viewModel.selectedGene,
                    neighboringGenes: viewModel.neighboringGenes,
                    onGeneSelected: { gene in
                        Task {
                            await viewModel.selectGene(gene)
                        }
                    }
                )
                .frame(height: 180)
                
                // Group Indicator with Exon Information
                groupIndicatorView
                
                // Gene Structure Visualization (Expandable)
                GeneStructureView(viewModel: viewModel, sceneManager: sceneManager, currentSequence: currentSequence)
                
                Divider()
                
                // Gene Information - Below image with proper spacing
                if viewModel.selectedGene != nil {
                    SequenceDetailView(viewModel: viewModel, currentSequence: currentSequence)
                }
            }
        }
    }
    
    // MARK: - Group Indicator
    private var groupIndicatorView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    // Group number
                    HStack(spacing: 4) {
                        Image(systemName: "list.number")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text(currentGroupInfo)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                // Region type badge with color coding
                Text(currentGroupExonInfo)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(getBadgeColor(for: currentGroupExonInfo))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // Position details
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text(currentGroupDetails)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .background(Color(.systemGray6))
            
            Divider()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading genome data...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    private func errorView(_ error: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text("Error")
                .font(.headline)
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task {
                    await viewModel.searchGene("BRCA1")
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Initializing...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationView {
        GenomeMapView(currentSequence: nil, sceneManager: DNASceneManager())
    }
}
