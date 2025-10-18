//
//  SearchSheet.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import SwiftUI

struct SearchSheet: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var searchText = ""
    @State private var searchType: SearchType = .accession
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var loadedSequence: DNASequence?
    @State private var showViewer = false
    
    enum SearchType: String, CaseIterable {
        case accession = "GenBank Accession"
        case pdbID = "PDB ID"
        case manual = "Manual Entry"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Search Type")) {
                    Picker("Type", selection: $searchType) {
                        ForEach(SearchType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Input")) {
                    switch searchType {
                    case .accession:
                        TextField("e.g., NM_007294.4", text: $searchText)
                            #if !os(macOS)
                            .autocapitalization(.allCharacters)
                            #endif
                        
                        Text("Enter NCBI GenBank accession number")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                    case .pdbID:
                        TextField("e.g., 1BNA", text: $searchText)
                            #if !os(macOS)
                            .autocapitalization(.allCharacters)
                            #endif
                        
                        Text("Enter PDB structure ID")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                    case .manual:
                        TextEditor(text: $searchText)
                            .frame(height: 150)
                            .font(.system(.body, design: .monospaced))
                        
                        Text("Enter DNA sequence (ATGC)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                
                Section {
                    Button(action: loadSequence) {
                        HStack {
                            if isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                            }
                            Text("Load Sequence")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(searchText.isEmpty || isLoading)
                }
                
                Section(header: Text("Examples")) {
                    Button("BRCA1 (NM_007294.4)") {
                        searchText = "NM_007294.4"
                        searchType = .accession
                    }
                    
                    Button("TP53 (NM_000546.6)") {
                        searchText = "NM_000546.6"
                        searchType = .accession
                    }
                    
                    Button("B-DNA (1BNA)") {
                        searchText = "1BNA"
                        searchType = .pdbID
                    }
                }
            }
            .navigationTitle("Load Sequence")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                #endif
            }
        }
        #if os(macOS)
        .sheet(isPresented: $showViewer) {
            if let sequence = loadedSequence {
                ViewerView(sequence: sequence, viewModel: DNAViewModel())
            }
        }
        #else
        .fullScreenCover(isPresented: $showViewer) {
            if let sequence = loadedSequence {
                ViewerView(sequence: sequence, viewModel: DNAViewModel())
            }
        }
        #endif
    }
    
    private func loadSequence() {
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                let sequence: DNASequence
                
                switch searchType {
                case .accession:
                    sequence = try await NCBIService.shared.fetchSequence(accession: searchText)
                    
                case .pdbID:
                    _ = try await PDBService.shared
                        .fetchStructure(pdbID: searchText)
                    // For now, create a placeholder sequence
                    sequence = DNASequence(
                        name: searchText,
                        pdbID: searchText,
                        sequence: "ATGC" // Placeholder
                    )
                    
                case .manual:
                    let cleanedSequence = searchText.uppercased()
                        .replacingOccurrences(of: " ", with: "")
                        .replacingOccurrences(of: "\n", with: "")
                    
                    guard cleanedSequence.allSatisfy({ "ATGCN".contains($0) }) else {
                        throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid DNA sequence. Only A, T, G, C, N allowed."])
                    }
                    
                    sequence = DNASequence(
                        name: "Custom Sequence",
                        sequence: cleanedSequence
                    )
                }
                
                // Cache the sequence
                try? CacheManager.shared.cacheSequence(sequence, forKey: sequence.accession ?? sequence.name)
                
                // Save to recent items
                let recentItem = RecentItem(
                    name: sequence.name,
                    type: searchType.rawValue
                )
                try? CacheManager.shared.saveRecentItem(recentItem)
                
                await MainActor.run {
                    loadedSequence = sequence
                    isLoading = false
                    showViewer = true
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    SearchSheet()
}

