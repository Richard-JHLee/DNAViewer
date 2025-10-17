//
//  MutationSheet.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import SwiftUI

struct MutationSheet: View {
    @Environment(\.dismiss) var dismiss
    let sequence: DNASequence
    
    @State private var mutationType: MutationType = .snp
    @State private var position: String = "0"
    @State private var newBase: String = "A"
    @State private var insertedBases: String = "A"
    @State private var deletionLength: String = "1"
    @State private var endPosition: String = "10"
    
    @State private var mutationResult: MutationSimulator.MutationEffect?
    @State private var showKnownMutations = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Mutation Type")) {
                    Picker("Type", selection: $mutationType) {
                        Text("Point Mutation").tag(MutationType.snp)
                        Text("Insertion").tag(MutationType.insertion)
                        Text("Deletion").tag(MutationType.deletion)
                        Text("Inversion").tag(MutationType.inversion)
                    }
                }
                
                Section(header: Text("Parameters")) {
                    TextField("Position (0-\(sequence.length - 1))", text: $position)
                        #if !os(macOS)
                        .keyboardType(.numberPad)
                        #endif
                    
                    switch mutationType {
                    case .snp, .substitution:
                        Picker("New Base", selection: $newBase) {
                            Text("A").tag("A")
                            Text("T").tag("T")
                            Text("G").tag("G")
                            Text("C").tag("C")
                        }
                        .pickerStyle(.segmented)
                        
                    case .insertion:
                        TextField("Bases to Insert (e.g., ATG)", text: $insertedBases)
                            #if !os(macOS)
                            .autocapitalization(.allCharacters)
                            #endif
                        
                    case .deletion:
                        TextField("Length to Delete", text: $deletionLength)
                            #if !os(macOS)
                            .keyboardType(.numberPad)
                            #endif
                        
                    case .inversion:
                        TextField("End Position", text: $endPosition)
                            #if !os(macOS)
                            .keyboardType(.numberPad)
                            #endif
                        
                    case .duplication:
                        TextField("Length to Duplicate", text: $deletionLength)
                            #if !os(macOS)
                            .keyboardType(.numberPad)
                            #endif
                    }
                }
                
                Section {
                    Button(action: simulateMutation) {
                        HStack {
                            Image(systemName: "bolt.fill")
                            Text("Simulate Mutation")
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                if let result = mutationResult {
                    Section(header: Text("Result")) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Effect:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(result.result.description)
                                    .fontWeight(.bold)
                                    .foregroundColor(colorForResult(result.result))
                            }
                            
                            Divider()
                            
                            Text("Original:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(result.originalSequence.prefix(60) + "...")
                                .font(.system(.caption, design: .monospaced))
                            
                            Text("Mutated:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(result.mutatedSequence.prefix(60) + "...")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.red)
                            
                            if let originalProtein = result.originalProtein,
                               let mutatedProtein = result.mutatedProtein {
                                Divider()
                                
                                Text("Original Protein:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(originalProtein.prefix(20) + "...")
                                    .font(.system(.caption, design: .monospaced))
                                
                                Text("Mutated Protein:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(mutatedProtein.prefix(20) + "...")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                if !sequence.mutations.isEmpty {
                    Section(header: Text("Known Pathogenic Mutations")) {
                        ForEach(sequence.mutations.prefix(5)) { mutation in
                            Button(action: {
                                loadMutation(mutation)
                            }) {
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
                }
            }
            .navigationTitle("Mutation Simulator")
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
    
    private func simulateMutation() {
        guard let pos = Int(position), pos >= 0, pos < sequence.length else {
            return
        }
        
        let result: MutationSimulator.MutationEffect
        
        switch mutationType {
        case .snp, .substitution:
            result = MutationSimulator.applyPointMutation(
                sequence: sequence.sequence,
                position: pos,
                newBase: newBase
            )
            
        case .insertion:
            result = MutationSimulator.applyInsertion(
                sequence: sequence.sequence,
                position: pos,
                insertedBases: insertedBases.uppercased()
            )
            
        case .deletion:
            guard let length = Int(deletionLength), length > 0 else { return }
            result = MutationSimulator.applyDeletion(
                sequence: sequence.sequence,
                position: pos,
                length: length
            )
            
        case .inversion:
            guard let endPos = Int(endPosition), endPos > pos else { return }
            result = MutationSimulator.applyInversion(
                sequence: sequence.sequence,
                startPosition: pos,
                endPosition: endPos
            )
            
        case .duplication:
            // Not implemented in this example
            return
        }
        
        mutationResult = result
    }
    
    private func loadMutation(_ mutation: Mutation) {
        position = "\(mutation.position)"
        
        switch mutation.type {
        case .snp, .substitution:
            mutationType = .snp
            newBase = mutation.altBase
            
        case .insertion:
            mutationType = .insertion
            insertedBases = mutation.altBase
            
        case .deletion:
            mutationType = .deletion
            deletionLength = "\(mutation.refBase.count)"
            
        case .inversion:
            mutationType = .inversion
            
        case .duplication:
            break
        }
    }
    
    private func colorForResult(_ result: MutationSimulator.MutationResult) -> Color {
        switch result {
        case .synonymous: return .green
        case .missense: return .orange
        case .nonsense: return .red
        case .frameshift: return .purple
        case .noChange: return .gray
        }
    }
}

#Preview {
    MutationSheet(sequence: DNASequence(
        name: "Sample",
        sequence: "ATGGCGATCGATCGATCG"
    ))
}

