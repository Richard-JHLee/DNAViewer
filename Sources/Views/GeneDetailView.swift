//
//  GeneDetailView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-18.
//

import SwiftUI

struct GeneDetailView: View {
    let gene: Gene
    let onApply: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(gene.symbol)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(gene.name)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                    
                    // Basic Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        InfoRow(label: "Gene ID", value: "\(gene.geneId)")
                        InfoRow(label: "Organism", value: gene.organism)
                        InfoRow(label: "Chromosome", value: gene.chromosome)
                        InfoRow(label: "Gene Type", value: gene.geneType)
                        InfoRow(label: "Taxonomy ID", value: "\(gene.taxId)")
                        
                        if !gene.aliases.isEmpty {
                            InfoRow(label: "Aliases", value: gene.aliases.joined(separator: ", "))
                        }
                    }
                    
                    Divider()
                    
                    // Description
                    if let description = gene.description {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Gene Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        onApply() // Close action
                    }
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    GeneDetailView(
        gene: Gene.sampleGenes[0],
        onApply: {}
    )
}