//
//  Codon.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import Foundation

struct Codon: Identifiable, Codable, Equatable {
    let id: UUID
    let sequence: String // 3-letter (e.g., "ATG")
    let aminoAcid: String // 1-letter (e.g., "M")
    let fullName: String // "Methionine"
    let isStartCodon: Bool
    let isStopCodon: Bool
    
    init(
        id: UUID = UUID(),
        sequence: String,
        aminoAcid: String,
        fullName: String,
        isStartCodon: Bool = false,
        isStopCodon: Bool = false
    ) {
        self.id = id
        self.sequence = sequence.uppercased()
        self.aminoAcid = aminoAcid
        self.fullName = fullName
        self.isStartCodon = isStartCodon
        self.isStopCodon = isStopCodon
    }
}

class CodonTable {
    static let shared = CodonTable()
    
    private let codonMap: [String: Codon]
    
    private init() {
        var map: [String: Codon] = [:]
        
        // Standard genetic code table
        let codons = [
            // Phenylalanine (F)
            ("TTT", "F", "Phenylalanine"),
            ("TTC", "F", "Phenylalanine"),
            
            // Leucine (L)
            ("TTA", "L", "Leucine"),
            ("TTG", "L", "Leucine"),
            ("CTT", "L", "Leucine"),
            ("CTC", "L", "Leucine"),
            ("CTA", "L", "Leucine"),
            ("CTG", "L", "Leucine"),
            
            // Isoleucine (I)
            ("ATT", "I", "Isoleucine"),
            ("ATC", "I", "Isoleucine"),
            ("ATA", "I", "Isoleucine"),
            
            // Methionine (M) - START
            ("ATG", "M", "Methionine"),
            
            // Valine (V)
            ("GTT", "V", "Valine"),
            ("GTC", "V", "Valine"),
            ("GTA", "V", "Valine"),
            ("GTG", "V", "Valine"),
            
            // Serine (S)
            ("TCT", "S", "Serine"),
            ("TCC", "S", "Serine"),
            ("TCA", "S", "Serine"),
            ("TCG", "S", "Serine"),
            ("AGT", "S", "Serine"),
            ("AGC", "S", "Serine"),
            
            // Proline (P)
            ("CCT", "P", "Proline"),
            ("CCC", "P", "Proline"),
            ("CCA", "P", "Proline"),
            ("CCG", "P", "Proline"),
            
            // Threonine (T)
            ("ACT", "T", "Threonine"),
            ("ACC", "T", "Threonine"),
            ("ACA", "T", "Threonine"),
            ("ACG", "T", "Threonine"),
            
            // Alanine (A)
            ("GCT", "A", "Alanine"),
            ("GCC", "A", "Alanine"),
            ("GCA", "A", "Alanine"),
            ("GCG", "A", "Alanine"),
            
            // Tyrosine (Y)
            ("TAT", "Y", "Tyrosine"),
            ("TAC", "Y", "Tyrosine"),
            
            // Histidine (H)
            ("CAT", "H", "Histidine"),
            ("CAC", "H", "Histidine"),
            
            // Glutamine (Q)
            ("CAA", "Q", "Glutamine"),
            ("CAG", "Q", "Glutamine"),
            
            // Asparagine (N)
            ("AAT", "N", "Asparagine"),
            ("AAC", "N", "Asparagine"),
            
            // Lysine (K)
            ("AAA", "K", "Lysine"),
            ("AAG", "K", "Lysine"),
            
            // Aspartic acid (D)
            ("GAT", "D", "Aspartic acid"),
            ("GAC", "D", "Aspartic acid"),
            
            // Glutamic acid (E)
            ("GAA", "E", "Glutamic acid"),
            ("GAG", "E", "Glutamic acid"),
            
            // Cysteine (C)
            ("TGT", "C", "Cysteine"),
            ("TGC", "C", "Cysteine"),
            
            // Tryptophan (W)
            ("TGG", "W", "Tryptophan"),
            
            // Arginine (R)
            ("CGT", "R", "Arginine"),
            ("CGC", "R", "Arginine"),
            ("CGA", "R", "Arginine"),
            ("CGG", "R", "Arginine"),
            ("AGA", "R", "Arginine"),
            ("AGG", "R", "Arginine"),
            
            // Glycine (G)
            ("GGT", "G", "Glycine"),
            ("GGC", "G", "Glycine"),
            ("GGA", "G", "Glycine"),
            ("GGG", "G", "Glycine"),
            
            // Stop codons
            ("TAA", "*", "Stop"),
            ("TAG", "*", "Stop"),
            ("TGA", "*", "Stop"),
        ]
        
        for (seq, aa, name) in codons {
            let isStart = seq == "ATG"
            let isStop = aa == "*"
            map[seq] = Codon(
                sequence: seq,
                aminoAcid: aa,
                fullName: name,
                isStartCodon: isStart,
                isStopCodon: isStop
            )
        }
        
        self.codonMap = map
    }
    
    func translate(_ codonSequence: String) -> Codon? {
        return codonMap[codonSequence.uppercased()]
    }
    
    func translateSequence(_ dnaSequence: String) -> [Codon] {
        var codons: [Codon] = []
        let sequence = dnaSequence.uppercased()
        
        for i in stride(from: 0, to: sequence.count - 2, by: 3) {
            let startIndex = sequence.index(sequence.startIndex, offsetBy: i)
            let endIndex = sequence.index(startIndex, offsetBy: 3)
            let codonSeq = String(sequence[startIndex..<endIndex])
            
            if let codon = translate(codonSeq) {
                codons.append(codon)
            }
        }
        
        return codons
    }
    
    func getAllCodons() -> [Codon] {
        return Array(codonMap.values).sorted { $0.sequence < $1.sequence }
    }
}

