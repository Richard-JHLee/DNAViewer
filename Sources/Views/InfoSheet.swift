//
//  InfoSheet.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import SwiftUI

struct InfoSheet: View {
    @Environment(\.dismiss) var dismiss
    let sequence: DNASequence
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Gene Information")) {
                    InfoRow(label: "Name", value: sequence.name)
                    
                    if let accession = sequence.accession {
                        InfoRow(label: "Accession", value: accession)
                    }
                    
                    if let chromosome = sequence.chromosome {
                        InfoRow(label: "Chromosome", value: chromosome)
                    }
                    
                    InfoRow(label: "Organism", value: sequence.organism)
                    InfoRow(label: "Type", value: sequence.geneType.rawValue)
                }
                
                Section(header: Text("Sequence Statistics")) {
                    InfoRow(label: "Length", value: "\(sequence.length) bp")
                    InfoRow(label: "GC Content", value: String(format: "%.2f%%", sequence.gcContent))
                    
                    let composition = SequenceAnalyzer.getBaseComposition(sequence.sequence)
                    InfoRow(label: "A", value: "\(composition["A"] ?? 0)")
                    InfoRow(label: "T", value: "\(composition["T"] ?? 0)")
                    InfoRow(label: "G", value: "\(composition["G"] ?? 0)")
                    InfoRow(label: "C", value: "\(composition["C"] ?? 0)")
                }
                
                if let summary = sequence.summary {
                    Section(header: Text("Function")) {
                        Text(summary)
                            .font(.body)
                    }
                }
                
                if let diseases = sequence.diseaseLinks, !diseases.isEmpty {
                    Section(header: Text("Associated Diseases")) {
                        ForEach(diseases, id: \.self) { disease in
                            HStack {
                                Image(systemName: "cross.case.fill")
                                    .foregroundColor(.red)
                                Text(disease)
                            }
                        }
                    }
                }
                
                if !sequence.mutations.isEmpty {
                    Section(header: Text("Known Mutations")) {
                        ForEach(sequence.mutations) { mutation in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mutation.displayNotation)
                                    .font(.headline)
                                
                                Text(mutation.consequence)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if let disease = mutation.disease {
                                    Text(disease)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section(header: Text("External Links")) {
                    if let accession = sequence.accession {
                        Link(destination: URL(string: "https://www.ncbi.nlm.nih.gov/nuccore/\(accession)")!) {
                            HStack {
                                Image(systemName: "link")
                                Text("NCBI Gene")
                                Spacer()
                                Image(systemName: "arrow.up.forward")
                            }
                        }
                    }
                    
                    Link(destination: URL(string: "https://www.genecards.org/")!) {
                        HStack {
                            Image(systemName: "link")
                            Text("GeneCards")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                        }
                    }
                }
            }
            .navigationTitle("Sequence Info")
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
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    InfoSheet(sequence: DNASequence(
        name: "BRCA1",
        accession: "NM_007294.4",
        sequence: "ATGCGATCG",
        chromosome: "17q21.31",
        summary: "DNA repair protein",
        diseaseLinks: ["Breast Cancer"]
    ))
}

