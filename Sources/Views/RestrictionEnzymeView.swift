//
//  RestrictionEnzymeView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-18.
//

import SwiftUI

// Helper types
struct RestrictionMap {
    let hits: [String: [RestrictionHit]]
    let totalSites: Int
    
    func sitesForEnzyme(_ enzyme: RestrictionEnzyme) -> Int {
        return hits[enzyme.name]?.count ?? 0
    }
}

struct DNAFragment: Identifiable {
    let id = UUID()
    let sequence: String
    let start: Int
    let end: Int
    var length: Int { sequence.count }
}

struct RestrictionEnzymeView: View {
    let sequence: DNASequence
    @ObservedObject var sceneManager: DNASceneManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedEnzymes: Set<RestrictionEnzyme> = []
    @State private var restrictionMap: RestrictionMap?
    @State private var showDigestionResult = false
    @State private var fragments: [DNAFragment] = []
    @State private var searchText = ""
    
    var filteredEnzymes: [RestrictionEnzyme] {
        if searchText.isEmpty {
            return defaultEnzymes
        }
        return defaultEnzymes.filter { enzyme in
            enzyme.name.lowercased().contains(searchText.lowercased()) ||
            enzyme.recognitionSite.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                searchBarView
                enzymeListView
                bottomActionBar
            }
            .navigationTitle("Restriction Enzymes")
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
                    Button("Clear") {
                        selectedEnzymes.removeAll()
                        restrictionMap = nil
                    }
                    .disabled(selectedEnzymes.isEmpty)
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear") {
                        selectedEnzymes.removeAll()
                        restrictionMap = nil
                    }
                    .disabled(selectedEnzymes.isEmpty)
                }
                #endif
            }
            .sheet(isPresented: $showDigestionResult) {
                DigestionResultView(fragments: fragments, enzymes: Array(selectedEnzymes))
            }
        }
    }
    
    private func toggleEnzyme(_ enzyme: RestrictionEnzyme) {
        if selectedEnzymes.contains(enzyme) {
            selectedEnzymes.remove(enzyme)
        } else {
            selectedEnzymes.insert(enzyme)
        }
    }
    
    private func analyzeSequence() {
        let analyzer = RestrictionSiteAnalyzer()
        let enzymes = Array(selectedEnzymes)
        let hits = analyzer.analyze(sequence: sequence.sequence, enzymes: enzymes)
        
        let totalSites = hits.values.flatMap { $0 }.count
        restrictionMap = RestrictionMap(hits: hits, totalSites: totalSites)
    }
    
    private func simulateDigestion() {
        // Simple simulation: find all cut sites and split sequence
        let analyzer = RestrictionSiteAnalyzer()
        let enzymes = Array(selectedEnzymes)
        let hits = analyzer.analyze(sequence: sequence.sequence, enzymes: enzymes)
        
        var allPositions: Set<Int> = []
        for siteList in hits.values {
            for site in siteList {
                allPositions.insert(site.position)
            }
        }
        
        let sortedPositions = allPositions.sorted()
        var tempFragments: [DNAFragment] = []
        
        if sortedPositions.isEmpty {
            tempFragments.append(DNAFragment(sequence: sequence.sequence, start: 0, end: sequence.length))
        } else {
            let seq = sequence.sequence
            var lastPos = 0
            
            for pos in sortedPositions {
                if pos > lastPos {
                    let startIdx = seq.index(seq.startIndex, offsetBy: max(0, lastPos))
                    let endIdx = seq.index(seq.startIndex, offsetBy: min(seq.count, pos))
                    let frag = String(seq[startIdx..<endIdx])
                    tempFragments.append(DNAFragment(sequence: frag, start: lastPos, end: pos))
                }
                lastPos = pos
            }
            
            // Last fragment
            if lastPos < seq.count {
                let startIdx = seq.index(seq.startIndex, offsetBy: lastPos)
                let frag = String(seq[startIdx...])
                tempFragments.append(DNAFragment(sequence: frag, start: lastPos, end: seq.count))
            }
        }
        
        fragments = tempFragments
        showDigestionResult = true
    }
    
    private func highlightCutSites() {
        guard let map = restrictionMap else { return }
        
        // Collect all cut positions
        var cutPositions: [Int] = []
        for siteList in map.hits.values {
            cutPositions.append(contentsOf: siteList.map { $0.position })
        }
        
        // Find the group containing the first cut site and navigate to it
        if let firstCutSite = cutPositions.first {
            let targetGroup = (firstCutSite / sceneManager.groupSize) + 1
            
            print("🔍 Cut site at position \(firstCutSite) -> Group \(targetGroup)")
            
            // Navigate to the group containing the cut site
            sceneManager.loadGroup(targetGroup)
            
            // Wait a moment for the scene to rebuild, then highlight positions
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.sceneManager.highlightPositions(cutPositions)
            }
        }
        
        dismiss()
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sequence.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("\(sequence.length) bp")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.blue.opacity(0.1))
    }
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search enzymes...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
    }
    
    private var enzymeListView: some View {
        List {
            Section(header: Text("Select Restriction Enzymes").font(.headline)) {
                ForEach(filteredEnzymes) { enzyme in
                    EnzymeRow(
                        enzyme: enzyme,
                        isSelected: selectedEnzymes.contains(enzyme),
                        siteCount: restrictionMap?.sitesForEnzyme(enzyme) ?? 0
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleEnzyme(enzyme)
                    }
                }
            }
        }
        #if os(macOS)
        .listStyle(SidebarListStyle())
        #else
        .listStyle(InsetGroupedListStyle())
        #endif
    }
    
    private var bottomActionBar: some View {
        VStack(spacing: 12) {
            if let map = restrictionMap {
                HStack {
                    Image(systemName: "scissors")
                        .foregroundColor(.blue)
                    Text("\(map.totalSites) cut sites found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(selectedEnzymes.count) enzymes selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            
            HStack(spacing: 12) {
                Button(action: analyzeSequence) {
                    HStack {
                        Image(systemName: "chart.bar.doc.horizontal")
                        Text("Analyze")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedEnzymes.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(selectedEnzymes.isEmpty)
                
                Button(action: simulateDigestion) {
                    HStack {
                        Image(systemName: "scissors.badge.ellipsis")
                        Text("Digest")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedEnzymes.isEmpty ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(selectedEnzymes.isEmpty)
                
                Button(action: highlightCutSites) {
                    HStack {
                        Image(systemName: "eye.fill")
                        Text("Show 3D")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedEnzymes.isEmpty || restrictionMap == nil ? Color.gray : Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(selectedEnzymes.isEmpty || restrictionMap == nil)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .shadow(radius: 2)
    }
}

// MARK: - Enzyme Row

struct EnzymeRow: View {
    let enzyme: RestrictionEnzyme
    let isSelected: Bool
    let siteCount: Int
    
    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(enzyme.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    if siteCount > 0 {
                        Text("\(siteCount) sites")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                
                Text(enzyme.recognitionSite)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Text(overhangTypeText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var overhangTypeText: String {
        return enzyme.overhang
    }
}

// MARK: - Digestion Result View

struct DigestionResultView: View {
    let fragments: [DNAFragment]
    let enzymes: [RestrictionEnzyme]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Summary header
                VStack(spacing: 8) {
                    Text("Digestion Complete")
                        .font(.title2)
                        .bold()
                    
                    Text("Enzymes: \(enzymes.map { $0.name }.joined(separator: ", "))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(fragments.count) fragments generated")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                
                // Fragments list
                List {
                    Section(header: Text("DNA Fragments").font(.headline)) {
                        ForEach(Array(fragments.enumerated()), id: \.element.id) { index, fragment in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Fragment \(index + 1)")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text("\(fragment.length) bp")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.2))
                                        .cornerRadius(8)
                                }
                                
                                Text("Position: \(fragment.start) - \(fragment.end)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if fragment.length <= 100 {
                                    Text(fragment.sequence)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.blue)
                                        .lineLimit(3)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                #if os(macOS)
                .listStyle(SidebarListStyle())
                #else
                .listStyle(InsetGroupedListStyle())
                #endif
            }
            .navigationTitle("Digestion Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    RestrictionEnzymeView(
        sequence: DNASequence(
            name: "Sample Gene",
            sequence: "ATGCGAATTCGATCGATCGATCGGATCCATCGATCG",
            summary: "Test sequence"
        ),
        sceneManager: DNASceneManager()
    )
}

