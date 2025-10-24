//
//  DNAViewModel.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import SwiftUI
import Combine

@MainActor
class DNAViewModel: ObservableObject {
    @Published var currentSequence: DNASequence?
    @Published var currentSequenceName: String = ""
    @Published var isLoading: Bool = false
    @Published var loadingProgress: String = ""
    @Published var error: String?
    // 2D 뷰 데이터
    @Published var ladderPairs: [BasePair] = []
    @Published var genomeMarks: [GeneMark] = []
    @Published var sequenceLength: Int = 0
    
    init() {
        print("🧬 DNAViewModel initialized")
    }
    
    // 기본 DNA 시퀀스 로드 (실제 BRCA1 유전자 데이터)
    func loadDefaultSequence() {
        print("🧬 Loading REAL BRCA1 gene sequence from Ensembl API...")
        isLoading = true
        loadingProgress = "Loading BRCA1 gene from Ensembl..."
        error = nil
        
        Task {
            do {
                // 실제 BRCA1 유전자 데이터를 Ensembl API에서 가져오기
                let realBRCA1Sequence = try await fetchRealBRCA1Sequence()
                
                // DNASequence 객체 생성
                let dnaSequence = DNASequence(
                    name: "BRCA1 (Breast Cancer Gene 1)",
                    sequence: realBRCA1Sequence,
                    chromosome: "17",
                    organism: "Homo sapiens",
                    features: [
                        GeneFeature(
                            type: .exon,
                            startIndex: 0,
                            endIndex: realBRCA1Sequence.count - 1,
                            description: "BRCA1 gene region"
                        )
                    ],
                    mutations: [
                        Mutation(
                            position: 185,
                            refBase: "A",
                            altBase: "G",
                            type: .substitution,
                            consequence: "Missense",
                            clinicalSignificance: .pathogenic,
                            disease: "Breast and ovarian cancer",
                            description: "Deleterious - Associated with increased breast cancer risk"
                        )
                    ],
                    summary: "DNA repair and tumor suppressor gene",
                    diseaseLinks: ["Breast cancer", "Ovarian cancer"]
                )
                
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1초 딜레이 (로딩 시뮬레이션)
                
                await MainActor.run {
                    self.currentSequence = dnaSequence
                    self.currentSequenceName = dnaSequence.name
                    self.isLoading = false
                    self.loadingProgress = ""
                    // 2D 데이터 채우기
                    self.ladderPairs = dnaSequence.basePairs
                    self.genomeMarks = dnaSequence.geneMarks
                    self.sequenceLength = dnaSequence.length
                    print("✅ Default DNA sequence loaded: \(dnaSequence.name)")
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to load default sequence: \(error.localizedDescription)"
                    self.isLoading = false
                    self.loadingProgress = ""
                    print("❌ Failed to load default sequence: \(error)")
                }
            }
        }
    }
    
    // 실제 BRCA1 유전자 시퀀스를 Ensembl API에서 가져오기
    private func fetchRealBRCA1Sequence() async throws -> String {
        print("🌐 Fetching REAL BRCA1 gene sequence from Ensembl API...")
        
        // Ensembl REST API를 통해 BRCA1 유전자 시퀀스 가져오기
        let urlString = "https://rest.ensembl.org/sequence/id/ENSG00000012048"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "DNAViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.setValue("text/plain", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "DNAViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }
        
        guard let sequence = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "DNAViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode sequence"])
        }
        
        let cleanedSequence = sequence.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        print("✅ Successfully fetched REAL BRCA1 sequence: \(cleanedSequence.count) bp")
        print("✅ Sequence preview: \(cleanedSequence.prefix(20))...")
        
        return cleanedSequence
    }
    
    // 선택된 유전자 로드 (실제 API 사용)
    func loadSelectedGene(_ geneName: String) {
        print("🧬 Loading selected gene from Ensembl API: \(geneName)")
        isLoading = true
        loadingProgress = "Loading \(geneName) from Ensembl..."
        error = nil
        
        Task {
            do {
                // 실제 유전자 데이터를 Ensembl API에서 가져오기
                let realSequence = try await fetchRealGeneSequence(geneName)
                
                await MainActor.run {
                    self.currentSequence = realSequence
                    self.currentSequenceName = realSequence.name
                    self.isLoading = false
                    self.loadingProgress = ""
                    self.ladderPairs = realSequence.basePairs
                    self.genomeMarks = realSequence.geneMarks
                    self.sequenceLength = realSequence.length
                    print("✅ Gene loaded from API: \(realSequence.name)")
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to load gene: \(error.localizedDescription)"
                    self.isLoading = false
                    self.loadingProgress = ""
                    print("❌ Failed to load gene from API: \(error)")
                }
            }
        }
    }
    
    // 실제 유전자 시퀀스를 Ensembl API에서 가져오기
    private func fetchRealGeneSequence(_ geneSymbol: String) async throws -> DNASequence {
        print("🌐 Fetching gene sequence for \(geneSymbol) from Ensembl API...")
        
        // Gene symbol을 Ensembl ID로 변환
        let geneMap: [String: String] = [
            "BRCA1": "ENSG00000012048",
            "TP53": "ENSG00000141510",
            "CFTR": "ENSG00000001626",
            "APOE": "ENSG00000130203"
        ]
        
        guard let ensemblID = geneMap[geneSymbol.uppercased()] else {
            throw NSError(domain: "DNAViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Gene \(geneSymbol) not supported yet"])
        }
        
        let urlString = "https://rest.ensembl.org/sequence/id/\(ensemblID)"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "DNAViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.setValue("text/plain", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "DNAViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }
        
        guard let sequence = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "DNAViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode sequence"])
        }
        
        let cleanedSequence = sequence.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Gene-specific metadata
        let geneInfo = getGeneMetadata(for: geneSymbol)
        
        let dnaSequence = DNASequence(
            name: "\(geneSymbol) (\(geneInfo.fullName))",
            sequence: cleanedSequence,
            chromosome: geneInfo.chromosome,
            organism: "Homo sapiens",
            features: [
                GeneFeature(
                    type: .exon,
                    startIndex: 0,
                    endIndex: cleanedSequence.count - 1,
                    description: "\(geneSymbol) gene region"
                )
            ],
            summary: geneInfo.summary,
            diseaseLinks: geneInfo.diseaseLinks
        )
        
        print("✅ Successfully fetched real gene sequence: \(cleanedSequence.count) bp")
        return dnaSequence
    }
    
    // Get gene metadata
    private func getGeneMetadata(for symbol: String) -> (fullName: String, chromosome: String, summary: String, diseaseLinks: [String]) {
        switch symbol.uppercased() {
        case "BRCA1":
            return ("Breast Cancer Gene 1", "17", "DNA repair and tumor suppressor gene", ["Breast cancer", "Ovarian cancer"])
        case "TP53":
            return ("Tumor Protein P53", "17", "Tumor suppressor and cell cycle regulation gene", ["Various cancers", "Li-Fraumeni syndrome"])
        case "CFTR":
            return ("Cystic Fibrosis Gene", "7", "Chloride channel protein", ["Cystic fibrosis"])
        case "APOE":
            return ("Apolipoprotein E", "19", "Lipid metabolism and neurological function", ["Alzheimer's disease"])
        default:
            return (symbol, "Unknown", "Gene function", [])
        }
    }
    
}

