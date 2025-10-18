//
//  LibraryView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import SwiftUI

struct LibraryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: DNAViewModel
    @State private var sampleGenes: [GeneInfo] = []
    @State private var selectedGene: GeneInfo?
    @State private var showViewer = false
    @State private var isLoadingSequence = false
    @State private var loadingProgress = ""
    @State private var loadedSequence: DNASequence?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                    ForEach(sampleGenes) { gene in
                        GeneCard(gene: gene) {
                            loadGeneFromNCBI(gene)
                        }
                    }
                }
                .padding()
            }
            .overlay {
                if isLoadingSequence {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            
                            Text(loadingProgress)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                }
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
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    private func loadSampleGenes() {
        print("📚 Loading sample genes...")
        
        // Load from JSON
        guard let url = Bundle.main.url(forResource: "SampleGenes", withExtension: "json") else {
            print("⚠️ SampleGenes.json not found, using defaults")
            loadDefaultGenes()
            return
        }
        
        guard let data = try? Data(contentsOf: url) else {
            print("⚠️ Failed to read SampleGenes.json, using defaults")
            loadDefaultGenes()
            return
        }
        
        guard let genes = try? JSONDecoder().decode([GeneInfo].self, from: data) else {
            print("⚠️ Failed to decode SampleGenes.json, using defaults")
            loadDefaultGenes()
            return
        }
        
        print("✅ Loaded \(genes.count) genes from JSON")
        sampleGenes = genes
    }
    
    private func loadDefaultGenes() {
        print("⚠️ Using default hardcoded genes (5 genes)")
        sampleGenes = [
            GeneInfo(id: "BRCA1", name: "BRCA1", symbol: "BRCA1", description: "Breast cancer susceptibility gene", chromosome: "17q21.31", diseases: ["Breast Cancer", "Ovarian Cancer"]),
            GeneInfo(id: "TP53", name: "TP53", symbol: "TP53", description: "Tumor suppressor protein", chromosome: "17p13.1", diseases: ["Li-Fraumeni Syndrome"]),
            GeneInfo(id: "CFTR", name: "CFTR", symbol: "CFTR", description: "Cystic fibrosis transmembrane conductance regulator", chromosome: "7q31.2", diseases: ["Cystic Fibrosis"]),
            GeneInfo(id: "HBB", name: "HBB", symbol: "HBB", description: "Hemoglobin subunit beta", chromosome: "11p15.4", diseases: ["Sickle Cell Disease"]),
            GeneInfo(id: "APOE", name: "APOE", symbol: "APOE", description: "Apolipoprotein E", chromosome: "19q13.32", diseases: ["Alzheimer's Disease"])
        ]
        print("✅ Default genes loaded: \(sampleGenes.map { $0.symbol })")
    }
    
    private func loadGeneFromNCBI(_ gene: GeneInfo) {
        print("👆 loadGeneFromNCBI called for: \(gene.symbol)")
        
        selectedGene = gene
        isLoadingSequence = true
        loadingProgress = "Loading \(gene.symbol) from NCBI..."
        errorMessage = nil
        
        print("⏳ isLoadingSequence = true, loadingProgress = \(loadingProgress)")
        
        Task {
            do {
                print("🌐 Task started - Fetching \(gene.symbol) from NCBI...")
                
                // SampleGenes.json에서 accession 가져오기
                guard let jsonGene = try? loadGeneFromJSON(id: gene.id),
                      let accession = jsonGene.accession else {
                    throw NCBIService.NCBIError.invalidURL
                }
                
                print("📡 Accession: \(accession)")
                loadingProgress = "Downloading from NCBI (\(accession))..."
                
                // NCBI API로 실제 데이터 가져오기
                let sequence = try await NCBIService.shared.fetchSequence(accession: accession)
                
                print("✅ Loaded \(sequence.sequence.count)bp from NCBI")
                
                // JSON의 추가 정보와 병합
                let strand: Strand = jsonGene.strand.lowercased() == "plus" ? .plus : .minus
                let geneType: GeneType = jsonGene.geneType.lowercased() == "coding" ? .coding : .nonCoding
                
                // Mutation 변환
                let mutations = jsonGene.mutations.map { mutJson -> Mutation in
                    Mutation(
                        position: mutJson.position,
                        refBase: mutJson.refBase,
                        altBase: mutJson.altBase,
                        type: MutationType(rawValue: mutJson.type) ?? .substitution,
                        consequence: mutJson.consequence ?? "",
                        clinicalSignificance: ClinicalSignificance(rawValue: mutJson.clinicalSignificance) ?? .uncertain,
                        disease: mutJson.disease,
                        description: mutJson.description
                    )
                }
                
                let enhancedSequence = DNASequence(
                    name: jsonGene.name,
                    accession: accession,
                    pdbID: jsonGene.pdbID,
                    sequence: sequence.sequence,
                    chromosome: jsonGene.chromosome,
                    startPos: jsonGene.startPos,
                    endPos: jsonGene.endPos,
                    strand: strand,
                    geneType: geneType,
                    organism: jsonGene.organism,
                    features: jsonGene.features,
                    mutations: mutations,
                    summary: jsonGene.summary,
                    diseaseLinks: jsonGene.diseaseLinks
                )
                
                await MainActor.run {
                    self.loadedSequence = enhancedSequence
                    self.isLoadingSequence = false
                    
                    // ViewModel에 새로운 시퀀스 설정
                    self.viewModel.currentSequence = enhancedSequence
                    
                    // LibraryView 닫기
                    self.dismiss()
                }
            } catch {
                await MainActor.run {
                    self.isLoadingSequence = false
                    self.errorMessage = "Failed to load \(gene.symbol): \(error.localizedDescription)"
                    print("❌ Error loading gene: \(error)")
                }
            }
        }
    }
    
    private func loadGeneFromJSON(id: String) throws -> DNASequenceJSON? {
        guard let url = Bundle.main.url(forResource: "SampleGenes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let genes = try? JSONDecoder().decode([DNASequenceJSON].self, from: data) else {
            return nil
        }
        return genes.first { $0.id == id }
    }
}

// JSON 디코딩용 구조체
struct DNASequenceJSON: Codable {
    let id: String
    let name: String
    let accession: String?
    let pdbID: String?
    let sequence: String
    let chromosome: String?
    let startPos: Int?
    let endPos: Int?
    let strand: String
    let geneType: String
    let organism: String
    let features: [GeneFeature]
    let mutations: [MutationJSON]
    let summary: String?
    let diseaseLinks: [String]?
}

struct MutationJSON: Codable {
    let id: String
    let position: Int
    let refBase: String
    let altBase: String
    let type: String
    let consequence: String?
    let clinicalSignificance: String
    let disease: String?
    let description: String?
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
        Button(action: {
            print("🎯 GeneCard tapped: \(gene.symbol)")
            action()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
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
    LibraryView(viewModel: DNAViewModel())
}

