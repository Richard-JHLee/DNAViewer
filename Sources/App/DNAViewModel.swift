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
    
    init() {
        print("🧬 DNAViewModel initialized")
    }
    
    // 기본 DNA 시퀀스 로드 (샘플 데이터)
    func loadDefaultSequence() {
        print("🧬 Loading default DNA sequence...")
        isLoading = true
        loadingProgress = "Loading sample gene..."
        error = nil
        
        Task {
            do {
                // BRCA1 유전자 샘플 (유방암 관련)
                let sampleSequence = """
                ATGGATTTATCTGCTCTTCGCGTTGAAGAAGTACAAAATGTCATTAATGCTATGCAGAAAATCTTAGAGTGTCCCATCTGTCTGGAGTTG
                ATCAAGGAACCTGTCTCCACAAAGTGTGACCACATATTTTGCAAATTTTGCATGCTGAAACTTCTCAACCAGAAGAAAGGGCCTTCACA
                GTGTCCTTTATGTAAGAATGATATAACCAAAAGGAGCCTACAAGAAAGTACGAGATTTAGTCAACTTGTTGAAGAGCTATTGAAAATCA
                TTTGTGCTTTTCAGCTTGACACAGGTTTGGAGTATGCAAACAGCTATAATTTTGCAAAAAAGGAAAATAACTCTCCTGAACATCTAAAA
                GATGAAGTTTCTATCATCCAAAGTATGGGCTACAGAAACCGTGCCAAAAGACTTCTACAGAGTGAACCCGAAAATCCTTCCTTGCAGGA
                AACCAGTCTCAGTGTCCAACTCTCTAACCTTGGAACTGTGAGAACTCTGAGGACAAAGCAGCGGATACAACCTCAAAAGACGTCTGTCT
                ACATTGAATTGGGATCTGATTCTTCTGAAGATACCGTTAATAAGGCAACTTATTGCAGTGTGGGAGATCAAGAATTGTTACAAATCACC
                CCTCAAGGAACCAGGGATGAAATCAGTTTGGATTCTGCAAAAAAGGCTGCTTGTGAATTTTCTGAGACGGATGTAACAAATACTGAACA
                TTAGTCCACGCAGTGCACTGCTCAGTCTAATTGTTGCAGCCTCTCCCCTTGGCTGATGCCATGCAGCACCTGTATTACGATAACCAGAA
                CCAGTCCAGTGTTTAATGAGCTCTTCAAATAATGGCTAAGGCAGGGATGCCAGGCCTGGCCAATGAGCTGTTGCATCCTGCCAGGTAAA
                """
                
                let cleanedSequence = sampleSequence.replacingOccurrences(of: "\n", with: "")
                    .replacingOccurrences(of: " ", with: "")
                    .uppercased()
                
                // DNASequence 객체 생성
                let dnaSequence = DNASequence(
                    name: "BRCA1 (Breast Cancer Gene 1)",
                    sequence: cleanedSequence,
                    chromosome: "17",
                    organism: "Homo sapiens",
                    features: [
                        GeneFeature(
                            type: .exon,
                            startIndex: 0,
                            endIndex: cleanedSequence.count - 1,
                            description: "Exon region"
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
    
    // 선택된 유전자 로드
    func loadSelectedGene(_ geneName: String) {
        print("🧬 Loading selected gene: \(geneName)")
        isLoading = true
        loadingProgress = "Loading \(geneName)..."
        error = nil
        
        Task {
            do {
                // 샘플 유전자 데이터 맵
                let geneSequences = getSampleGeneSequences()
                
                guard let geneData = geneSequences[geneName] else {
                    throw NSError(domain: "DNAViewModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "Gene not found"])
                }
                
                try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5초 딜레이
                
                await MainActor.run {
                    self.currentSequence = geneData
                    self.currentSequenceName = geneData.name
                    self.isLoading = false
                    self.loadingProgress = ""
                    print("✅ Gene loaded: \(geneData.name)")
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to load gene: \(error.localizedDescription)"
                    self.isLoading = false
                    self.loadingProgress = ""
                    print("❌ Failed to load gene: \(error)")
                }
            }
        }
    }
    
    // 샘플 유전자 데이터 가져오기
    private func getSampleGeneSequences() -> [String: DNASequence] {
        var sequences: [String: DNASequence] = [:]
        
        // BRCA1
        let brca1Seq = """
        ATGGATTTATCTGCTCTTCGCGTTGAAGAAGTACAAAATGTCATTAATGCTATGCAGAAAATCTTAGAGTGTCCCATCTGTCTGGAGTTG
        ATCAAGGAACCTGTCTCCACAAAGTGTGACCACATATTTTGCAAATTTTGCATGCTGAAACTTCTCAACCAGAAGAAAGGGCCTTCACA
        GTGTCCTTTATGTAAGAATGATATAACCAAAAGGAGCCTACAAGAAAGTACGAGATTTAGTCAACTTGTTGAAGAGCTATTGAAAATCA
        """.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: " ", with: "")
        
        sequences["BRCA1"] = DNASequence(
            name: "BRCA1 (Breast Cancer Gene 1)",
            sequence: brca1Seq,
            chromosome: "17",
            organism: "Homo sapiens",
            summary: "DNA repair and tumor suppressor gene",
            diseaseLinks: ["Breast cancer", "Ovarian cancer"]
        )
        
        // TP53
        let tp53Seq = """
        ATGGAGGAGCCGCAGTCAGATCCTAGCGTCGAGCCCCCTCTGAGTCAGGAAACATTTTCAGACCTATGGAAACTACTTCCTGAAAACAAC
        GTTCTGTCCCCCTTGCCGTCCCAAGCAATGGATGATTTGATGCTGTCCCCGGACGATATTGAACAATGGTTCACTGAAGACCCAGGTCCA
        GATGAAGCTCCCAGAATGCCAGAGGCTGCTCCCCCCGTGGCCCCTGCACCAGCAGCTCCTACACCGGCGGCCCCTGCACCAGCCCCCTCC
        """.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: " ", with: "")
        
        sequences["TP53"] = DNASequence(
            name: "TP53 (Tumor Protein P53)",
            sequence: tp53Seq,
            chromosome: "17",
            organism: "Homo sapiens",
            summary: "Tumor suppressor and cell cycle regulation gene",
            diseaseLinks: ["Various cancers", "Li-Fraumeni syndrome"]
        )
        
        // CFTR
        let cftrSeq = """
        ATGCAGAGGTCGCCTTAGCAAGTTGGCCGATTCAAGTTTGCAGAAGAAGCAAAGCATGTCCATCTCAGAGCCCATTGTGAGAGCCTATGT
        TGATCAATACTTGTCCAGAGAGCAGCTTTATGGAGTGGACAGGCTCACCGCGCTCCTCAGTGCCATTGCCGCCAAGATGCAGAAGGAGGC
        TGAGAAGATTTTCCGAGGCAGACTACTGCGACAGCAACTTGCAAGTGCCTGATGGGCCGTTGATCTTTGGGCTGTGTGGATTGCTATGAC
        """.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: " ", with: "")
        
        sequences["CFTR"] = DNASequence(
            name: "CFTR (Cystic Fibrosis Gene)",
            sequence: cftrSeq,
            chromosome: "7",
            organism: "Homo sapiens",
            summary: "Chloride channel protein",
            diseaseLinks: ["Cystic fibrosis"]
        )
        
        return sequences
    }
}

