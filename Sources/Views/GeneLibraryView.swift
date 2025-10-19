//
//  GeneLibraryView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-18.
//

import SwiftUI

struct GeneLibraryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: GeneCategory?
    @State private var selectedSubCategory: GeneSubCategory?
    @State private var filteredGenes: [Gene] = []
    @State private var showGeneDetail = false
    @State private var selectedGene: Gene?
    @State private var showMainView = false
    @State private var geneToApply: Gene?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                if selectedCategory == nil {
                    // Category selection
                    categoryGridView
                } else if selectedSubCategory == nil {
                    // Sub-category selection
                    subCategoryView
                } else {
                    // Gene list
                    geneListView
                }
            }
            .navigationTitle("Gene Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if selectedCategory != nil || selectedSubCategory != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back") {
                            if selectedSubCategory != nil {
                                selectedSubCategory = nil
                                filteredGenes = []
                            } else {
                                selectedCategory = nil
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showGeneDetail) {
            if let gene = selectedGene {
                GeneDetailView(gene: gene) { selectedGene in
                    self.geneToApply = selectedGene
                    self.showMainView = true
                    self.showGeneDetail = false
                }
            }
        }
        .sheet(isPresented: $showMainView) {
            if let gene = geneToApply {
                // Convert Gene to DNASequence and show main view
                let dnaSequence = DNASequence(
                    name: "\(gene.symbol) - \(gene.name)",
                    sequence: generateSampleSequence(for: gene),
                    summary: gene.description ?? ""
                )
                ViewerView(sequence: dnaSequence, viewModel: DNAViewModel())
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("DNA Atlas")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            if let category = selectedCategory {
                Text(category.koreanName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let subCategory = selectedSubCategory {
                Text(subCategory.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
    }
    
    // MARK: - Category Grid
    
    private var categoryGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(GeneCategory.allCases, id: \.self) { category in
                    CategoryCard(
                        title: category.koreanName,
                        subtitle: category.rawValue,
                        icon: iconForCategory(category)
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Sub Category View
    
    private var subCategoryView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if let category = selectedCategory {
                    ForEach(subCategoriesFor(category), id: \.self) { subCategory in
                        SubCategoryRow(
                            title: subCategory.rawValue,
                            count: geneCountForSubCategory(subCategory)
                        ) {
                            selectedSubCategory = subCategory
                            filteredGenes = genesForSubCategory(subCategory)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Gene List View
    
    private var geneListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredGenes) { gene in
                    GeneCard(gene: gene) {
                        selectedGene = gene
                        showGeneDetail = true
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Functions
    
    private func iconForCategory(_ category: GeneCategory) -> String {
        switch category {
        case .organism: return "figure.2.and.child.holdinghands"
        case .geneType: return "function"
        case .chromosome: return "circle.grid.3x3"
        case .status: return "checkmark.circle"
        case .symbolPrefix: return "textformat.abc"
        }
    }
    
    private func subCategoriesFor(_ category: GeneCategory) -> [GeneSubCategory] {
        return GeneSubCategory.allCases.filter { $0.parentCategory == category }
    }
    
    private func geneCountForSubCategory(_ subCategory: GeneSubCategory) -> Int {
        return genesForSubCategory(subCategory).count
    }
    
    private func genesForSubCategory(_ subCategory: GeneSubCategory) -> [Gene] {
        return Gene.sampleGenes.filter { gene in
            switch subCategory.parentCategory {
            case .organism:
                return gene.organism == subCategory.rawValue
            case .geneType:
                return gene.geneType == subCategory.rawValue
            case .chromosome:
                return gene.chromosome == subCategory.rawValue
            case .status:
                return true // Assume all sample genes are "live"
            case .symbolPrefix:
                return gene.symbol.hasPrefix(subCategory.rawValue)
            }
        }
    }
    
    private func generateSampleSequence(for gene: Gene) -> String {
        // Generate a sample DNA sequence for the gene
        let bases = ["A", "T", "G", "C"]
        var sequence = ""
        for _ in 0..<1000 {
            sequence += bases.randomElement() ?? "A"
        }
        return sequence
    }
}

// MARK: - Category Card

struct CategoryCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sub Category Row

struct SubCategoryRow: View {
    let title: String
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(count) genes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Gene Card

struct GeneCard: View {
    let gene: Gene
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(gene.symbol)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("ID: \(gene.geneId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                        
                        Spacer()
                    }
                    
                    Text(gene.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    if let description = gene.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                }
                
                Spacer()
                
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    GeneLibraryView()
}
