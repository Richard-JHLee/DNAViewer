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
    @State private var expandedCategory: String? = nil // For accordion
    
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
                            Text("Choose from 22 commonly used vectors across different applications")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // Group vectors by type
                            let vectorsByType = Dictionary(grouping: CloningVector.commonVectors, by: { $0.type })
                            let sortedTypes = vectorsByType.keys.sorted()
                            
                            ForEach(sortedTypes, id: \.self) { type in
                                VStack(alignment: .leading, spacing: 0) {
                                    // Accordion header
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            if expandedCategory == type {
                                                expandedCategory = nil
                                            } else {
                                                expandedCategory = type
                                            }
                                        }
                                    }) {
                                        HStack(spacing: 12) {
                                            // Chevron icon
                                            Image(systemName: expandedCategory == type ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                                                .foregroundColor(.blue)
                                                .font(.title3)
                                                .animation(.spring(response: 0.3), value: expandedCategory)
                                            
                                            // Folder icon
                                            Image(systemName: "folder.fill")
                                                .foregroundColor(.blue)
                                                .font(.body)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(type)
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)
                                                
                                                Text("\(vectorsByType[type]?.count ?? 0) vectors available")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            // Badge
                                            Text("\(vectorsByType[type]?.count ?? 0)")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.blue)
                                                .cornerRadius(12)
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(expandedCategory == type ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(expandedCategory == type ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    // Accordion content (vectors list)
                                    if expandedCategory == type {
                                        VStack(spacing: 8) {
                                            ForEach(vectorsByType[type] ?? []) { vector in
                                                VectorRow(vector: vector, isSelected: selectedVector == vector)
                                                    .contentShape(Rectangle())
                                                    .onTapGesture {
                                                        selectedVector = vector
                                                        if step == 1 { step = 2 }
                                                    }
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.top, 8)
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .scale.combined(with: .opacity)
                                        ))
                                    }
                                }
                                .padding(.vertical, 4)
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
                            Text("Enter the DNA sequence to insert or use real gene data from NCBI")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // Prominent "Use Current Gene" button
                            VStack(spacing: 12) {
                                Button(action: {
                                    insertSequence = sequence.sequence
                                }) {
                                    VStack(spacing: 8) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "dna")
                                                .font(.system(size: 24))
                                                .foregroundColor(.white)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Use Real Gene from NCBI")
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                
                                                Text("Current: \(sequence.name)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.white.opacity(0.9))
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "arrow.right.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                        }
                                        
                                        HStack {
                                            Image(systemName: "info.circle.fill")
                                                .font(.caption)
                                            Text("\(sequence.length) bp • Real sequence data")
                                                .font(.caption)
                                            Spacer()
                                            Text(sequence.organism)
                                                .font(.caption2)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(Color.white.opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                        .foregroundColor(.white.opacity(0.9))
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text("OR")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.semibold)
                            }
                            
                            // Manual sequence input
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Enter Custom Sequence")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    if !insertSequence.isEmpty {
                                        Button("Clear") {
                                            insertSequence = ""
                                        }
                                        .font(.caption)
                                        .buttonStyle(.bordered)
                                    }
                                }
                                
                                TextEditor(text: $insertSequence)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(height: 100)
                                    .border(Color.gray.opacity(0.3))
                                    .cornerRadius(4)
                            }
                            
                            if !insertSequence.isEmpty {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("\(insertSequence.count) bp ready for cloning")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                
                                Button("Continue to Cloning") {
                                    step = 4
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
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
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(vector.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(vector.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Label("\(vector.size) bp", systemImage: "ruler")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
        }
        .padding(12)
        #if os(macOS)
        .background(isSelected ? Color.blue.opacity(0.15) : Color(NSColor.controlBackgroundColor))
        #else
        .background(isSelected ? Color.blue.opacity(0.15) : Color(.systemGray6))
        #endif
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
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
        // Basic Cloning Vectors
        CloningVector(id: "puc19", name: "pUC19", size: 2686, type: "Cloning", description: "High copy number cloning vector with lacZ"),
        CloningVector(id: "puc18", name: "pUC18", size: 2686, type: "Cloning", description: "High copy cloning vector (reverse MCS)"),
        CloningVector(id: "pbr322", name: "pBR322", size: 4361, type: "Cloning", description: "Classic cloning vector with amp/tet resistance"),
        CloningVector(id: "pbluescript", name: "pBluescript SK+", size: 2961, type: "Cloning", description: "High copy cloning with T3/T7 promoters"),
        
        // Bacterial Expression Vectors
        CloningVector(id: "pet28a", name: "pET-28a(+)", size: 5369, type: "Bacterial Expression", description: "IPTG-inducible with N/C-His-tag"),
        CloningVector(id: "pet15b", name: "pET-15b", size: 5708, type: "Bacterial Expression", description: "N-terminal His-tag expression"),
        CloningVector(id: "pet21a", name: "pET-21a(+)", size: 5443, type: "Bacterial Expression", description: "C-terminal His-tag expression"),
        CloningVector(id: "pgex4t1", name: "pGEX-4T-1", size: 4969, type: "Bacterial Expression", description: "GST fusion protein expression"),
        CloningVector(id: "pgex6p1", name: "pGEX-6P-1", size: 4984, type: "Bacterial Expression", description: "GST fusion with PreScission site"),
        CloningVector(id: "pmal", name: "pMAL-c5X", size: 5677, type: "Bacterial Expression", description: "MBP fusion protein expression"),
        
        // Mammalian Expression Vectors
        CloningVector(id: "pcdna3", name: "pcDNA3.1(+)", size: 5428, type: "Mammalian Expression", description: "CMV promoter, neomycin resistance"),
        CloningVector(id: "pcdna4", name: "pcDNA4/TO", size: 5107, type: "Mammalian Expression", description: "Tet-inducible mammalian expression"),
        CloningVector(id: "pcmv", name: "pCMV-Tag2", size: 4729, type: "Mammalian Expression", description: "FLAG-tag mammalian expression"),
        CloningVector(id: "pcineo", name: "pCI-neo", size: 5515, type: "Mammalian Expression", description: "CMV enhancer/promoter vector"),
        
        // Lentiviral Vectors
        CloningVector(id: "plko", name: "pLKO.1-puro", size: 6472, type: "Lentiviral", description: "shRNA expression, puromycin selection"),
        CloningVector(id: "plenti", name: "pLenti-CMV-GFP-Puro", size: 11036, type: "Lentiviral", description: "CMV-driven GFP expression"),
        
        // Gateway Vectors
        CloningVector(id: "pdonr221", name: "pDONR221", size: 4470, type: "Gateway Entry", description: "Gateway entry clone vector"),
        CloningVector(id: "pdest17", name: "pDEST17", size: 6152, type: "Gateway Destination", description: "Gateway E. coli expression"),
        
        // Yeast Vectors
        CloningVector(id: "yep24", name: "YEp24", size: 11546, type: "Yeast Episomal", description: "2μ-based yeast episomal plasmid"),
        CloningVector(id: "ycp50", name: "YCp50", size: 9285, type: "Yeast Centromeric", description: "Low copy yeast centromeric plasmid"),
        
        // Plant Vectors
        CloningVector(id: "pbi121", name: "pBI121", size: 14000, type: "Plant Binary", description: "Agrobacterium-mediated plant transformation"),
        CloningVector(id: "pcambia", name: "pCAMBIA1300", size: 8878, type: "Plant Binary", description: "Plant transformation with hygromycin")
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

