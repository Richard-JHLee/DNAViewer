//
//  VirtualCloningView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-18.
//

import SwiftUI

struct VirtualCloningView: View {
    let sequence: DNASequence
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedVector: CloningVector? = nil
    @State private var selectedEnzyme1: RestrictionEnzyme? = nil
    @State private var selectedEnzyme2: RestrictionEnzyme? = nil
    @State private var insertSequence: String = ""
    @State private var showResult = false
    @State private var clonedSequence: String = ""
    @State private var step = 1
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Progress indicator
                    ProgressView(value: Double(step), total: 4)
                        .padding()
                    
                    // Step 1: Select Vector
                    StepCard(
                        number: 1,
                        title: "Select Cloning Vector",
                        isActive: step >= 1,
                        isCompleted: selectedVector != nil
                    ) {
                        VStack(spacing: 12) {
                            ForEach(CloningVector.commonVectors) { vector in
                                VectorRow(vector: vector, isSelected: selectedVector == vector)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedVector = vector
                                        if step == 1 { step = 2 }
                                    }
                            }
                        }
                    }
                    
                    // Step 2: Select Restriction Enzymes
                    StepCard(
                        number: 2,
                        title: "Select Restriction Enzymes",
                        isActive: step >= 2,
                        isCompleted: selectedEnzyme1 != nil && selectedEnzyme2 != nil
                    ) {
                        VStack(spacing: 16) {
                            Text("Choose two compatible enzymes for digestion")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // Enzyme 1
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Enzyme 1 (5' end)")
                                    .font(.subheadline)
                                    .bold()
                                
                                Picker("Enzyme 1", selection: $selectedEnzyme1) {
                                    Text("Select...").tag(nil as RestrictionEnzyme?)
                                    ForEach(defaultEnzymes, id: \.name) { enzyme in
                                        Text("\(enzyme.name) - \(enzyme.recognitionSite)")
                                            .tag(enzyme as RestrictionEnzyme?)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            // Enzyme 2
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Enzyme 2 (3' end)")
                                    .font(.subheadline)
                                    .bold()
                                
                                Picker("Enzyme 2", selection: $selectedEnzyme2) {
                                    Text("Select...").tag(nil as RestrictionEnzyme?)
                                    ForEach(defaultEnzymes, id: \.name) { enzyme in
                                        Text("\(enzyme.name) - \(enzyme.recognitionSite)")
                                            .tag(enzyme as RestrictionEnzyme?)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            if selectedEnzyme1 != nil && selectedEnzyme2 != nil {
                                Button("Continue") {
                                    step = 3
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                    
                    // Step 3: Prepare Insert
                    StepCard(
                        number: 3,
                        title: "Prepare DNA Insert",
                        isActive: step >= 3,
                        isCompleted: !insertSequence.isEmpty
                    ) {
                        VStack(spacing: 16) {
                            Text("Enter the DNA sequence to insert (or select from gene)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Button("Use Current Gene") {
                                    insertSequence = sequence.sequence
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Clear") {
                                    insertSequence = ""
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            TextEditor(text: $insertSequence)
                                .font(.system(.body, design: .monospaced))
                                .frame(height: 100)
                                .border(Color.gray.opacity(0.3))
                            
                            if !insertSequence.isEmpty {
                                Text("\(insertSequence.count) bp")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                
                                Button("Continue") {
                                    step = 4
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                    
                    // Step 4: Perform Cloning
                    StepCard(
                        number: 4,
                        title: "Perform Virtual Cloning",
                        isActive: step >= 4,
                        isCompleted: showResult
                    ) {
                        VStack(spacing: 16) {
                            if let vector = selectedVector,
                               let enzyme1 = selectedEnzyme1,
                               let enzyme2 = selectedEnzyme2,
                               !insertSequence.isEmpty {
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    CloningInfoRow(label: "Vector", value: vector.name)
                                    CloningInfoRow(label: "Enzymes", value: "\(enzyme1.name) + \(enzyme2.name)")
                                    CloningInfoRow(label: "Insert Size", value: "\(insertSequence.count) bp")
                                    CloningInfoRow(label: "Vector Size", value: "\(vector.size) bp")
                                    CloningInfoRow(label: "Expected Size", value: "\(vector.size + insertSequence.count) bp")
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                                
                                Button(action: performCloning) {
                                    HStack {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                        Text("Perform Cloning")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                
                                if showResult {
                                    Divider()
                                    
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("✅ Cloning Successful!")
                                            .font(.headline)
                                            .foregroundColor(.green)
                                        
                                        Text("Final construct: \(clonedSequence.count) bp")
                                            .font(.subheadline)
                                        
                                        ScrollView(.horizontal) {
                                            Text(clonedSequence.prefix(200))
                                                .font(.system(.caption, design: .monospaced))
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Button("Export Result") {
                                            exportResult()
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                    .padding()
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Virtual Cloning")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        resetCloning()
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Reset") {
                        resetCloning()
                    }
                }
                #endif
            }
        }
    }
    
    private func performCloning() {
        guard let vector = selectedVector,
              let enzyme1 = selectedEnzyme1,
              let enzyme2 = selectedEnzyme2 else { return }
        
        // Simulate cloning process
        // 1. Digest vector with enzymes
        // 2. Digest insert with same enzymes
        // 3. Ligate insert into vector
        
        // For simplicity, just concatenate: vector + enzyme1 site + insert + enzyme2 site
        let site1 = enzyme1.recognitionSite
        let site2 = enzyme2.recognitionSite
        
        clonedSequence = "VECTOR_BACKBONE_\(vector.size)bp" + site1 + insertSequence + site2 + "VECTOR_BACKBONE_END"
        
        showResult = true
    }
    
    private func resetCloning() {
        selectedVector = nil
        selectedEnzyme1 = nil
        selectedEnzyme2 = nil
        insertSequence = ""
        showResult = false
        clonedSequence = ""
        step = 1
    }
    
    private func exportResult() {
        // TODO: Implement export functionality
        print("Exporting cloned sequence: \(clonedSequence.count) bp")
    }
}

// MARK: - Supporting Views

struct StepCard<Content: View>: View {
    let number: Int
    let title: String
    let isActive: Bool
    let isCompleted: Bool
    let content: Content
    
    init(number: Int, title: String, isActive: Bool, isCompleted: Bool, @ViewBuilder content: () -> Content) {
        self.number = number
        self.title = title
        self.isActive = isActive
        self.isCompleted = isCompleted
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green : (isActive ? Color.blue : Color.gray))
                        .frame(width: 32, height: 32)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(Font.system(size: 16, weight: .bold))
                    } else {
                        Text("\(number)")
                            .foregroundColor(.white)
                            .font(Font.system(size: 16, weight: .bold))
                    }
                }
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(isActive ? .primary : .secondary)
                
                Spacer()
            }
            
            if isActive {
                content
                    .padding()
                    #if os(macOS)
                    .background(Color(NSColor.windowBackgroundColor))
                    #else
                    .background(Color(.systemBackground))
                    #endif
                    .cornerRadius(8)
                    .shadow(radius: 2)
            }
        }
        .padding()
        .background(isActive ? Color.blue.opacity(0.05) : Color.clear)
        .cornerRadius(12)
    }
}

struct VectorRow: View {
    let vector: CloningVector
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(vector.name)
                    .font(.headline)
                
                Text("\(vector.size) bp • \(vector.type)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        #if os(macOS)
        .background(isSelected ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
        #else
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
        #endif
        .cornerRadius(8)
    }
}

struct CloningInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .bold()
        }
    }
}

// MARK: - Cloning Vector Model

struct CloningVector: Identifiable, Equatable {
    let id: String
    let name: String
    let size: Int
    let type: String
    let description: String
    
    static let commonVectors: [CloningVector] = [
        CloningVector(id: "puc19", name: "pUC19", size: 2686, type: "Plasmid", description: "High copy number cloning vector"),
        CloningVector(id: "pbr322", name: "pBR322", size: 4361, type: "Plasmid", description: "Classic cloning vector"),
        CloningVector(id: "pcdna3", name: "pcDNA3.1", size: 5428, type: "Expression", description: "Mammalian expression vector"),
        CloningVector(id: "pet28a", name: "pET-28a", size: 5369, type: "Expression", description: "Bacterial expression vector with His-tag"),
        CloningVector(id: "pgex", name: "pGEX-4T-1", size: 4969, type: "Expression", description: "GST fusion protein expression")
    ]
}

#Preview {
    VirtualCloningView(
        sequence: DNASequence(
            name: "Sample Gene",
            sequence: "ATGCGAATTCGATCGATCGATCGGATCCATCGATCG",
            summary: "Test sequence"
        )
    )
}

