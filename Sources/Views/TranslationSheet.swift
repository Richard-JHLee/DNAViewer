//
//  TranslationSheet.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import SwiftUI

struct TranslationSheet: View {
    @Environment(\.dismiss) var dismiss
    let sequence: DNASequence
    
    @State private var selectedFrame: Int = 0
    @State private var showCodonTable = false
    @State private var showDetailedCodons = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Frame Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reading Frame")
                            .font(.headline)
                        
                        Picker("Frame", selection: $selectedFrame) {
                            Text("Frame +1").tag(0)
                            Text("Frame +2").tag(1)
                            Text("Frame +3").tag(2)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)
                    
                    // DNA Sequence
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DNA Sequence")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: true) {
                            Text(getFramedSequence())
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                #if os(macOS)
                                .background(Color(NSColor.controlBackgroundColor))
                                #else
                                .background(Color(.systemGray6))
                                #endif
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Translated Protein
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amino Acid Sequence")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: true) {
                            Text(getTranslatedSequence())
                                .font(.system(.title3, design: .monospaced))
                                .padding()
                                #if os(macOS)
                                .background(Color(NSColor.controlBackgroundColor))
                                #else
                                .background(Color(.systemGray6))
                                #endif
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    // ORF Finder Results
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Open Reading Frames")
                            .font(.headline)
                        
                        let orfs = SequenceAnalyzer.findORFs(sequence.sequence)
                        
                        if orfs.isEmpty {
                            Text("No ORFs found (minimum 75 bp)")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(Array(orfs.prefix(5).enumerated()), id: \.offset) { index, orf in
                                ORFCard(orf: orf, index: index + 1)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // 코돈 상세 보기 토글
                    Toggle("상세 코돈 번역 보기", isOn: $showDetailedCodons)
                        .padding(.horizontal)
                    
                    // 상세 코돈 번역 결과
                    if showDetailedCodons {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Codon Translation (first 50)")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVStack(spacing: 4) {
                                ForEach(Array(getDetailedCodons().prefix(50).enumerated()), id: \.offset) { index, item in
                                    DetailedCodonRow(
                                        position: selectedFrame + (index * 3) + 1,
                                        codon: item
                                    )
                                }
                                
                                if getDetailedCodons().count > 50 {
                                    Text("... (\(getDetailedCodons().count - 50) more codons)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding()
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                    
                    // Codon Table Button
                    Button(action: { showCodonTable = true }) {
                        HStack {
                            Image(systemName: "table")
                            Text("View Codon Table")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding()
                }
                .padding(.vertical)
            }
            .navigationTitle("Translation")
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
            .sheet(isPresented: $showCodonTable) {
                CodonTableView()
            }
        }
    }
    
    private func getFramedSequence() -> String {
        let start = selectedFrame
        guard start < sequence.sequence.count else { return "" }
        
        let startIndex = sequence.sequence.index(sequence.sequence.startIndex, offsetBy: start)
        return String(sequence.sequence[startIndex...])
    }
    
    private func getTranslatedSequence() -> String {
        let framedSeq = getFramedSequence()
        let codons = CodonTable.shared.translateSequence(framedSeq)
        return codons.map { $0.aminoAcid }.joined(separator: " ")
    }
    
    private func getDetailedCodons() -> [Codon] {
        let framedSeq = getFramedSequence()
        return CodonTable.shared.translateSequence(framedSeq)
    }
}

// MARK: - Detailed Codon Row Component

struct DetailedCodonRow: View {
    let position: Int
    let codon: Codon
    
    var body: some View {
        HStack(spacing: 12) {
            // Position
            Text("\(position)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)
            
            // Codon sequence
            Text(codon.sequence)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(codonColor)
                .frame(width: 50)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(codonBackground)
                .cornerRadius(6)
            
            // Arrow
            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Amino Acid
            HStack(spacing: 4) {
                Text(codon.aminoAcid)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                
                if codon.isStartCodon || codon.isStopCodon {
                    Text(codon.isStartCodon ? "START" : "STOP")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(codon.isStartCodon ? Color.green : Color.red)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Full name
            Text(codon.fullName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        #if os(macOS)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        #else
        .background(Color(.systemGray6).opacity(0.3))
        #endif
        .cornerRadius(8)
    }
    
    private var codonColor: Color {
        if codon.isStartCodon {
            return .green
        } else if codon.isStopCodon {
            return .red
        } else {
            return .primary
        }
    }
    
    private var codonBackground: Color {
        if codon.isStartCodon {
            return Color.green.opacity(0.2)
        } else if codon.isStopCodon {
            return Color.red.opacity(0.2)
        } else {
            return Color.blue.opacity(0.1)
        }
    }
}

struct ORFCard: View {
    let orf: SequenceAnalyzer.ORF
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("ORF #\(index)")
                    .font(.headline)
                
                Spacer()
                
                Text("\(orf.length) bp")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            
            HStack {
                Text("Frame: \(orf.frame)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Position: \(orf.startPosition)-\(orf.endPosition)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(orf.proteinSequence.prefix(50) + (orf.proteinSequence.count > 50 ? "..." : ""))
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding()
        #if os(macOS)
        .background(Color(NSColor.controlBackgroundColor))
        #else
        .background(Color(.systemGray6))
        #endif
        .cornerRadius(12)
    }
}

struct CodonTableView: View {
    @Environment(\.dismiss) var dismiss
    
    let codons = CodonTable.shared.getAllCodons()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(groupedCodons().sorted(by: { $0.key < $1.key }), id: \.key) { aminoAcid, codonList in
                    Section(header: Text("\(aminoAcid) - \(codonList.first?.fullName ?? "")")) {
                        ForEach(codonList, id: \.id) { codon in
                            HStack {
                                Text(codon.sequence)
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                if codon.isStartCodon {
                                    Text("START")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                                
                                if codon.isStopCodon {
                                    Text("STOP")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Genetic Code")
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
    }
    
    private func groupedCodons() -> [String: [Codon]] {
        Dictionary(grouping: codons, by: { $0.aminoAcid })
    }
}

#Preview {
    TranslationSheet(sequence: DNASequence(
        name: "Sample",
        sequence: "ATGGCGATCGATCGATCGATCGATCGATAA"
    ))
}

