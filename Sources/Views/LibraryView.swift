//
//  LibraryView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import SwiftUI

enum GeneCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case proteinCoding = "Protein Coding"
    case oncogenes = "Oncogenes"
    case tumorSuppressors = "Tumor Suppressors"
    case nonCodingRNA = "Non-coding RNA"
    case dnaRepair = "DNA Repair"
    case transcriptionFactors = "Transcription Factors"
    case immune = "Immune/HLA"
    case mitochondrial = "Mitochondrial"
    case cellCycle = "Cell Cycle"
    case apoptosis = "Apoptosis"
    
    var id: String { rawValue }
    
    var esearchTerm: String {
        switch self {
        case .all:
            return "Homo sapiens[Organism]"
        case .proteinCoding:
            // We will filter by ESummary genetype later to avoid fragile term
            return "Homo sapiens[Organism]"
        case .oncogenes:
            return "Homo sapiens[Organism] AND (oncogene[All Fields] OR proto-oncogene[All Fields])"
        case .tumorSuppressors:
            return "Homo sapiens[Organism] AND (\"tumor suppressor\"[All Fields] OR \"tumour suppressor\"[All Fields])"
        case .nonCodingRNA:
            return "Homo sapiens[Organism] AND (non-coding RNA OR lncRNA OR microRNA OR miRNA OR snoRNA OR snRNA)"
        case .dnaRepair:
            return "Homo sapiens[Organism] AND \"DNA repair\""
        case .transcriptionFactors:
            return "Homo sapiens[Organism] AND \"transcription factor\""
        case .immune:
            return "Homo sapiens[Organism] AND (immune OR HLA)"
        case .mitochondrial:
            return "Homo sapiens[Organism] AND mitochondr*"
        case .cellCycle:
            return "Homo sapiens[Organism] AND \"cell cycle\""
        case .apoptosis:
            return "Homo sapiens[Organism] AND apoptosis"
        }
    }
}

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
    @State private var selectedCategory: GeneCategory = .all
    @State private var isLoadingList: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(GeneCategory.allCases) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top])

                if selectedCategory == .all {
                    // Show category selection grid
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                            ForEach(GeneCategory.allCases.filter { $0 != .all }) { cat in
                                Button {
                                    selectedCategory = cat
                                } label: {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "books.vertical.fill")
                                                .font(.largeTitle)
                                                .foregroundColor(.blue)
                                            Spacer()
                                        }
                                        Text(cat.rawValue)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Text("Tap to view genes")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
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
                        .padding()
                    }
                } else {
                    // Show genes for selected category
                    ScrollView {
                        if isLoadingList {
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("Loading...")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                        } else if sampleGenes.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "tray")
                                    .font(.system(size: 44))
                                    .foregroundColor(.secondary)
                                Text("No results")
                                    .font(.headline)
                                Text("Try another category or refine your query.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                                ForEach(sampleGenes) { gene in
                                    GeneCard(gene: gene) {
                                        loadGeneFromNCBI(gene)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
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
        .onChange(of: selectedCategory) { _ in
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
        // In All mode we only show the category grid; skip API
        if selectedCategory == .all {
            sampleGenes = []
            return
        }
        // Debounce concurrent loads
        if isLoadingList { return }
        isLoadingList = true
        print("📚 Loading sample genes (category=\(selectedCategory.rawValue))...")
        Task {
            defer { Task { @MainActor in isLoadingList = false } }
            // Build disjoint terms by excluding previous categories (fixed order)
            let base = "Homo sapiens[Organism]"
            func not(_ term: String) -> String { return "NOT (\(term))" }
            let qOnco = "(oncogene[All Fields] OR proto-oncogene[All Fields])"
            let qTS = "(\"tumor suppressor\"[All Fields] OR \"tumour suppressor\"[All Fields])"
            let qNonCoding = "(non-coding RNA OR lncRNA OR microRNA OR miRNA OR snoRNA OR snRNA)"
            let qDNARepair = "(\"DNA repair\")"
            let qTF = "(\"transcription factor\")"
            let qImmune = "(immune OR HLA)"
            let qMito = "(mitochondr*)"
            let qCellCycle = "(\"cell cycle\")"
            let qApoptosis = "(apoptosis)"

            // Fixed priority: ProteinCoding -> Oncogenes -> TumorSuppressors -> NonCodingRNA -> DNARepair -> TF -> Immune -> Mito -> CellCycle -> Apoptosis
            let excludeOnco = [qNonCoding, qDNARepair, qTF, qImmune, qMito, qCellCycle, qApoptosis].joined(separator: " OR ")
            let excludeTS = [qOnco, qNonCoding, qDNARepair, qTF, qImmune, qMito, qCellCycle, qApoptosis].joined(separator: " OR ")
            let excludeNonCoding = [qOnco, qTS, qDNARepair, qTF, qImmune, qMito, qCellCycle, qApoptosis].joined(separator: " OR ")
            let excludeDNARepair = [qOnco, qTS, qNonCoding, qTF, qImmune, qMito, qCellCycle, qApoptosis].joined(separator: " OR ")
            let excludeTF = [qOnco, qTS, qNonCoding, qDNARepair, qImmune, qMito, qCellCycle, qApoptosis].joined(separator: " OR ")
            let excludeImmune = [qOnco, qTS, qNonCoding, qDNARepair, qTF, qMito, qCellCycle, qApoptosis].joined(separator: " OR ")
            let excludeMito = [qOnco, qTS, qNonCoding, qDNARepair, qTF, qImmune, qCellCycle, qApoptosis].joined(separator: " OR ")
            let excludeCellCycle = [qOnco, qTS, qNonCoding, qDNARepair, qTF, qImmune, qMito, qApoptosis].joined(separator: " OR ")
            let excludeApoptosis = [qOnco, qTS, qNonCoding, qDNARepair, qTF, qImmune, qMito, qCellCycle].joined(separator: " OR ")

            var term: String = selectedCategory.esearchTerm
            switch selectedCategory {
            case .proteinCoding:
                // Use ESummary-driven protein-coding UIDs as disjoint base (exclude others via NOT keywords)
                if let uids = try? await NCBIService.shared.proteinCodingUIDs(retmax: 20), let list = try? await NCBIService.shared.esummaryGeneInfos(uids: uids) {
                    print("✅ Loaded \(list.count) genes from NCBI API for category: Protein Coding (disjoint)")
                    await MainActor.run { sampleGenes = list }
                    return
                }
            case .oncogenes:
                term = "\(base) AND \(qOnco) AND \(not(excludeOnco))"
            case .tumorSuppressors:
                term = "\(base) AND \(qTS) AND \(not(excludeTS))"
            case .nonCodingRNA:
                term = "\(base) AND \(qNonCoding) AND \(not(excludeNonCoding))"
            case .dnaRepair:
                term = "\(base) AND \(qDNARepair) AND \(not(excludeDNARepair))"
            case .transcriptionFactors:
                term = "\(base) AND \(qTF) AND \(not(excludeTF))"
            case .immune:
                term = "\(base) AND \(qImmune) AND \(not(excludeImmune))"
            case .mitochondrial:
                term = "\(base) AND \(qMito) AND \(not(excludeMito))"
            case .cellCycle:
                term = "\(base) AND \(qCellCycle) AND \(not(excludeCellCycle))"
            case .apoptosis:
                term = "\(base) AND \(qApoptosis) AND \(not(excludeApoptosis))"
            case .all:
                term = base
            }

            if let uids = try? await NCBIService.shared.esearchUIDs(term: term, retmax: 20), let list = try? await NCBIService.shared.esummaryGeneInfos(uids: uids) {
                print("✅ Loaded \(list.count) genes from NCBI API for category: \(selectedCategory.rawValue) (disjoint)")
                await MainActor.run { sampleGenes = list }
            } else {
                await MainActor.run { sampleGenes = [] }
            }
        }
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
                
                // Resolve accession from API using elink gene->nuccore; fallback to esearch by symbol
                var accession: String?
                let linked = try? await NCBIService.shared.resolveAccessionsFromGeneUID(gene.id, retmax: 1)
                accession = linked?.first
                if accession == nil {
                    let hits = try await NCBIService.shared.searchGene(term: "\(gene.symbol)[Gene] AND Homo sapiens[orgn]")
                    accession = hits.first
                }

                guard let acc = accession else { throw NCBIService.NCBIError.invalidURL }

                print("📡 Accession: \(acc)")
                loadingProgress = "Downloading from NCBI (\(acc))..."

                // Fetch sequence by accession
                let sequence = try await NCBIService.shared.fetchSequence(accession: acc)
                
                print("✅ Loaded \(sequence.sequence.count)bp from NCBI")
                
                // JSON의 추가 정보와 병합
                let jsonGene = try? loadGeneFromJSON(id: gene.id)
                let strand: Strand = (jsonGene?.strand.lowercased() == "plus") ? .plus : .minus
                let geneType: GeneType = (jsonGene?.geneType.lowercased() == "coding") ? .coding : .nonCoding
                
                // Mutation 변환
                let mutations = (jsonGene?.mutations ?? []).map { mutJson -> Mutation in
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
                    name: jsonGene?.name ?? gene.symbol,
                    accession: acc,
                    pdbID: jsonGene?.pdbID,
                    sequence: sequence.sequence,
                    chromosome: jsonGene?.chromosome,
                    startPos: jsonGene?.startPos,
                    endPos: jsonGene?.endPos,
                    strand: strand,
                    geneType: geneType,
                    organism: jsonGene?.organism ?? "Homo sapiens",
                    features: jsonGene?.features ?? [],
                    mutations: mutations,
                    summary: jsonGene?.summary,
                    diseaseLinks: jsonGene?.diseaseLinks
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

