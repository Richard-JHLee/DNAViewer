//
//  RestrictionEnzymeView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-18.
//

import SwiftUI

struct RestrictionEnzymeView: View {
    let sequence: DNASequence
    @ObservedObject var sceneManager: DNASceneManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedEnzymes: Set<RestrictionEnzyme> = []
    @State private var restrictionMap: RestrictionMap?
    @State private var searchText = ""
    @State private var showDigestionResult = false
    @State private var showGelElectrophoresis = false
    @State private var showCloningProcess = false
    @State private var showTransformation = false
    @State private var showVerification = false
    @State private var availableEnzymes: [RestrictionEnzyme] = []
    @State private var enzymeSiteCounts: [String: Int] = [:]
    @State private var isAnalyzing = false
    @State private var showOnlyAvailable = true
    
    private var filteredEnzymes: [RestrictionEnzyme] {
        let enzymesToFilter = showOnlyAvailable ? availableEnzymes : RestrictionEnzyme.all
        
        if searchText.isEmpty {
            return enzymesToFilter
        } else {
            return enzymesToFilter.filter { enzyme in
                enzyme.name.localizedCaseInsensitiveContains(searchText) ||
                enzyme.sequence.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                searchBarView
                filterToggleView
                enzymeListView
                bottomActionBar
                
                // Educational Features Section
                if restrictionMap != nil && !selectedEnzymes.isEmpty {
                    VStack(spacing: 12) {
                        Text("Educational Features")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.top)
                        
                        HStack(spacing: 8) {
                            Button(action: startGelElectrophoresis) {
                                VStack {
                                    Image(systemName: "rectangle.stack")
                                        .font(.title2)
                                    Text("Gel Electrophoresis")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                            
                            Button(action: startCloningProcess) {
                                VStack {
                                    Image(systemName: "link")
                                        .font(.title2)
                                    Text("Cloning Process")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                            }
                        }
                        
                        HStack(spacing: 8) {
                            Button(action: startTransformation) {
                                VStack {
                                    Image(systemName: "arrow.down.circle")
                                        .font(.title2)
                                    Text("Transformation")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple.opacity(0.1))
                                .foregroundColor(.purple)
                                .cornerRadius(8)
                            }
                            
                            Button(action: startVerification) {
                                VStack {
                                    Image(systemName: "checkmark.shield")
                                        .font(.title2)
                                    Text("Verification")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .foregroundColor(.orange)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Restriction Enzymes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            analyzeSequenceForAvailableEnzymes()
        }
        .sheet(isPresented: $showDigestionResult) {
            if let map = restrictionMap {
                let fragments = createFragmentsFromCutSites(map: map)
                DigestionResultView(fragments: fragments, enzymes: Array(selectedEnzymes))
            }
        }
        .sheet(isPresented: $showGelElectrophoresis) {
            if let map = restrictionMap {
                let fragments = createFragmentsFromCutSites(map: map)
                GelElectrophoresisView(fragments: fragments, enzymes: Array(selectedEnzymes))
            }
        }
        .sheet(isPresented: $showCloningProcess) {
            if let map = restrictionMap {
                let targetDNA = createTargetDNAFromCutSites(map: map)
                let vectorDNA = DNAFragment(sequence: "GCTAGCTAGCTAGCTA", start: 0, end: 16)
                CloningVisualizationView(targetDNA: targetDNA, vectorDNA: vectorDNA)
            }
        }
        .sheet(isPresented: $showTransformation) {
            TransformationAnimationView()
        }
        .sheet(isPresented: $showVerification) {
            VerificationGuideView()
        }
    }
    
    // MARK: - Actions
    
    private func toggleEnzyme(_ enzyme: RestrictionEnzyme) {
        if selectedEnzymes.contains(enzyme) {
            selectedEnzymes.remove(enzyme)
        } else {
            selectedEnzymes.insert(enzyme)
        }
    }
    
    private func analyzeSequenceForAvailableEnzymes() {
        print("🧬 Analyzing sequence for available restriction enzymes...")
        print("📊 Sequence length: \(sequence.length) bp")
        print("📊 Sequence preview: \(String(sequence.sequence.prefix(50)))...")
        
        isAnalyzing = true
        
        Task {
            let analyzer = RestrictionSiteAnalyzer()
            let allEnzymes = RestrictionEnzyme.all
            
            print("🔍 Testing \(allEnzymes.count) restriction enzymes...")
            
            let hitsDict = analyzer.analyze(sequence: sequence.sequence, enzymes: allEnzymes)
            
            await MainActor.run {
                var available: [RestrictionEnzyme] = []
                var siteCounts: [String: Int] = [:]
                
                for enzyme in allEnzymes {
                    if let hits = hitsDict[enzyme.name] {
                        available.append(enzyme)
                        siteCounts[enzyme.name] = hits.count
                        print("✅ \(enzyme.name): \(hits.count) sites found")
                    }
                }
                
                availableEnzymes = available.sorted { $0.name < $1.name }
                enzymeSiteCounts = siteCounts
                isAnalyzing = false
                
                print("📋 Found \(available.count) available enzymes out of \(allEnzymes.count) total")
                print("📋 Available enzymes: \(available.map { $0.name }.joined(separator: ", "))")
            }
        }
    }
    
    private func analyzeSequence() {
        let analyzer = RestrictionSiteAnalyzer()
        let enzymes = Array(selectedEnzymes)
        let hitsDict = analyzer.analyze(sequence: sequence.sequence, enzymes: enzymes)
        
        // Convert [String: [RestrictionHit]] to [RestrictionEnzyme: [RestrictionSite]]
        var enzymeHits: [RestrictionEnzyme: [RestrictionSite]] = [:]
        for enzyme in enzymes {
            if let hits = hitsDict[enzyme.name] {
                let sites = hits.map { hit in
                    RestrictionSite(enzyme: enzyme, position: hit.position, matchedSequence: enzyme.sequence)
                }
                enzymeHits[enzyme] = sites
            }
        }
        
        let totalSites = enzymeHits.values.flatMap { $0 }.count
        restrictionMap = RestrictionMap(hits: enzymeHits, totalSites: totalSites)
    }
    
    private func simulateDigestion() {
        analyzeSequence()
        showDigestionResult = true
    }
    
    private func highlightCutSites() {
        guard let map = restrictionMap else { return }
        
        // Collect all cut positions
        var cutPositions: [Int] = []
        for siteList in map.hits.values {
            cutPositions.append(contentsOf: siteList.map { $0.position })
        }
        
        print("🎯 Highlighting \(cutPositions.count) cut sites: \(cutPositions)")
        
        // Use the sceneManager's highlightPositions which handles group navigation automatically
        sceneManager.highlightPositions(cutPositions)
        
        dismiss()
    }
    
    // MARK: - Educational Features
    
    private func startGelElectrophoresis() {
        showGelElectrophoresis = true
    }
    
    private func startCloningProcess() {
        showCloningProcess = true
    }
    
    private func startTransformation() {
        showTransformation = true
    }
    
    private func startVerification() {
        showVerification = true
    }
    
    private func createFragmentsFromCutSites(map: RestrictionMap) -> [DNAFragment] {
        var fragments: [DNAFragment] = []
        let cutPositions = map.hits.values.flatMap { $0.map { $0.position } }.sorted()
        var lastPosition = 0
        
        for position in cutPositions {
            if position > lastPosition {
                let fragment = DNAFragment(
                    sequence: String(sequence.sequence.dropFirst(lastPosition).prefix(position - lastPosition)),
                    start: lastPosition,
                    end: position
                )
                fragments.append(fragment)
            }
            lastPosition = position
        }
        
        // Add last fragment
        if lastPosition < sequence.sequence.count {
            let fragment = DNAFragment(
                sequence: String(sequence.sequence.dropFirst(lastPosition)),
                start: lastPosition,
                end: sequence.sequence.count
            )
            fragments.append(fragment)
        }
        
        return fragments
    }
    
    private func createTargetDNAFromCutSites(map: RestrictionMap) -> DNAFragment {
        if let firstCutSite = map.hits.values.flatMap({ $0.map { $0.position } }).first {
            let start = max(0, firstCutSite - 50)
            let end = min(sequence.sequence.count, firstCutSite + 50)
            return DNAFragment(
                sequence: String(sequence.sequence.dropFirst(start).prefix(end - start)),
                start: start,
                end: end
            )
        }
        
        // Default fragment if no cut sites
        return DNAFragment(
            sequence: String(sequence.sequence.prefix(100)),
            start: 0,
            end: 100
        )
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sequence.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Text("\(sequence.length) bp")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !isAnalyzing && !availableEnzymes.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "scissors")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("\(availableEnzymes.count) available enzymes")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }
                }
            }
            
            // Sequence preview
            if sequence.length > 0 {
                Text("Preview: \(String(sequence.sequence.prefix(30)))...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .font(.system(.caption, design: .monospaced))
            }
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
    
    private var filterToggleView: some View {
        HStack {
            Button(action: { showOnlyAvailable.toggle() }) {
                HStack(spacing: 8) {
                    Image(systemName: showOnlyAvailable ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(showOnlyAvailable ? .green : .gray)
                    
                    Text(showOnlyAvailable ? "Available Only" : "All Enzymes")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
            }
            
            Spacer()
            
            if isAnalyzing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Analyzing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("\(availableEnzymes.count) available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }
    
    private var enzymeListView: some View {
        List {
            Section(header: Text("Select Restriction Enzymes").font(.headline)) {
                ForEach(filteredEnzymes) { enzyme in
                    EnzymeRow(
                        enzyme: enzyme,
                        isSelected: selectedEnzymes.contains(enzyme),
                        siteCount: enzymeSiteCounts[enzyme.name] ?? 0,
                        isAvailable: availableEnzymes.contains(enzyme)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleEnzyme(enzyme)
                    }
                }
            }
        }
        #if os(macOS)
        .listStyle(PlainListStyle())
        #endif
    }
    
    private var bottomActionBar: some View {
        VStack(spacing: 12) {
            // Summary info
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
    }
}

// MARK: - Supporting Views

struct EnzymeRow: View {
    let enzyme: RestrictionEnzyme
    let isSelected: Bool
    let siteCount: Int
    let isAvailable: Bool
    
    var body: some View {
        HStack {
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(enzyme.name)
                        .font(.headline)
                        .foregroundColor(isAvailable ? .primary : .secondary)
                    
                    Spacer()
                    
                    // Availability indicator
                    if isAvailable {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Text(enzyme.sequence)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(isAvailable ? .secondary : .gray)
                
                HStack {
                    Text(overhangTypeText)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    if isAvailable {
                        if siteCount > 0 {
                            Text("\(siteCount) sites")
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                        } else {
                            Text("Available")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    } else {
                        Text("No match")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(isAvailable ? 1.0 : 0.6)
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
    
    @State private var showGelElectrophoresis = false
    @State private var showCloningProcess = false
    @State private var showTransformation = false
    @State private var showVerification = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Summary header
                VStack(spacing: 8) {
                    Text("Digestion Results")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.primary)
                    
                    Text("\(fragments.count) fragments generated")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                
                // Fragments list
                List {
                    ForEach(Array(fragments.enumerated()), id: \.offset) { index, fragment in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Fragment \(index + 1)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("\(fragment.length) bp")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .fontWeight(.semibold)
                            }
                            
                            Text("Position: \(fragment.start) - \(fragment.end)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Sequence: \(fragment.sequence)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Educational Features Section
                VStack(spacing: 16) {
                    Text("Next Steps: Choose an Educational Feature")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.top)
                    
                    // First row: Gel Electrophoresis and Cloning
                    HStack(spacing: 12) {
                        Button(action: { showGelElectrophoresis = true }) {
                            VStack(spacing: 8) {
                                Image(systemName: "rectangle.stack")
                                    .font(.title2)
                                Text("Gel Electrophoresis")
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                        }
                        
                        Button(action: { showCloningProcess = true }) {
                            VStack(spacing: 8) {
                                Image(systemName: "link")
                                    .font(.title2)
                                Text("Cloning Process")
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(10)
                        }
                    }
                    
                    // Second row: Transformation and Verification
                    HStack(spacing: 12) {
                        Button(action: { showTransformation = true }) {
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.down.circle")
                                    .font(.title2)
                                Text("Transformation")
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
                            .cornerRadius(10)
                        }
                        
                        Button(action: { showVerification = true }) {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.shield")
                                    .font(.title2)
                                Text("Verification")
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(10)
                        }
                    }
                    
                    // Close button
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showGelElectrophoresis) {
            GelElectrophoresisView(fragments: fragments, enzymes: enzymes)
        }
        .sheet(isPresented: $showCloningProcess) {
            let targetDNA = fragments.first ?? DNAFragment(sequence: "ATCG", start: 0, end: 4)
            let vectorDNA = DNAFragment(sequence: "GCTAGCTAGCTAGCTA", start: 0, end: 16)
            CloningVisualizationView(targetDNA: targetDNA, vectorDNA: vectorDNA)
        }
        .sheet(isPresented: $showTransformation) {
            TransformationAnimationView()
        }
        .sheet(isPresented: $showVerification) {
            VerificationGuideView()
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
