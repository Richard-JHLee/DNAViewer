//
//  LibraryView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import SwiftUI

struct LibraryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var sampleGenes: [GeneInfo] = []
    @State private var selectedGene: GeneInfo?
    @State private var showViewer = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                    ForEach(sampleGenes) { gene in
                        GeneCard(gene: gene) {
                            selectedGene = gene
                            showViewer = true
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Gene Library")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
        }
        .onAppear {
            loadSampleGenes()
        }
        #if os(macOS)
        .sheet(isPresented: $showViewer) {
            if let gene = selectedGene {
                ViewerView(sequence: createSequence(from: gene))
            }
        }
        #else
        .fullScreenCover(isPresented: $showViewer) {
            if let gene = selectedGene {
                ViewerView(sequence: createSequence(from: gene))
            }
        }
        #endif
    }
    
    private func loadSampleGenes() {
        // Load from JSON
        guard let url = Bundle.main.url(forResource: "SampleGenes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let genes = try? JSONDecoder().decode([GeneInfo].self, from: data) else {
            loadDefaultGenes()
            return
        }
        
        sampleGenes = genes
    }
    
    private func loadDefaultGenes() {
        sampleGenes = [
            GeneInfo(id: "BRCA1", name: "BRCA1", symbol: "BRCA1", description: "Breast cancer susceptibility gene", chromosome: "17q21.31", diseases: ["Breast Cancer", "Ovarian Cancer"]),
            GeneInfo(id: "TP53", name: "TP53", symbol: "TP53", description: "Tumor suppressor protein", chromosome: "17p13.1", diseases: ["Li-Fraumeni Syndrome"]),
            GeneInfo(id: "CFTR", name: "CFTR", symbol: "CFTR", description: "Cystic fibrosis transmembrane conductance regulator", chromosome: "7q31.2", diseases: ["Cystic Fibrosis"]),
            GeneInfo(id: "HBB", name: "HBB", symbol: "HBB", description: "Hemoglobin subunit beta", chromosome: "11p15.4", diseases: ["Sickle Cell Disease"]),
            GeneInfo(id: "APOE", name: "APOE", symbol: "APOE", description: "Apolipoprotein E", chromosome: "19q13.32", diseases: ["Alzheimer's Disease"])
        ]
    }
    
    private func createSequence(from gene: GeneInfo) -> DNASequence {
        // For demo, create a sample sequence
        return DNASequence(
            name: gene.name,
            sequence: String(repeating: "ATGC", count: 100),
            chromosome: gene.chromosome,
            summary: gene.description,
            diseaseLinks: gene.diseases
        )
    }
}

struct GeneInfo: Identifiable, Codable {
    let id: String
    let name: String
    let symbol: String
    let description: String
    let chromosome: String
    let diseases: [String]
}

struct GeneCard: View {
    let gene: GeneInfo
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "dna")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
                
                Text(gene.symbol)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(gene.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Label(gene.chromosome, systemImage: "mappin.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if let disease = gene.diseases.first {
                        Label(disease, systemImage: "cross.case.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            #if os(macOS)
            .background(Color(NSColor.controlBackgroundColor))
            #else
            .background(Color(.systemBackground))
            #endif
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LibraryView()
}

