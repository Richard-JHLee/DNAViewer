//
//  GenomeMapView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-22.
//

import SwiftUI

struct GenomeMapView: View {
    @StateObject private var viewModel = GeneViewModel()
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            searchBar
            
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
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            TextField("Search gene (e.g., BRCA1)", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    Task {
                        await viewModel.searchGene(searchText)
                    }
                }
            
            Button("Search") {
                Task {
                    await viewModel.searchGene(searchText)
                }
            }
            .disabled(searchText.isEmpty || viewModel.isLoading)
        }
        .padding()
    }
    
    // MARK: - Main Content
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Chromosome Ideogram
            ChromosomeIdeogramView(
                selectedGene: viewModel.selectedGene,
                neighboringGenes: viewModel.neighboringGenes,
                onGeneSelected: { gene in
                    Task {
                        await viewModel.selectGene(gene)
                    }
                }
            )
            .frame(height: 200)
            
            Divider()
            
            // Sequence Detail View
            if viewModel.selectedGene != nil {
                SequenceDetailView(viewModel: viewModel)
            }
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
                    await viewModel.searchGene(searchText)
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
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("Search for a gene")
                .font(.headline)
            Text("Enter a gene symbol like BRCA1 to get started")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationView {
        GenomeMapView()
    }
}
