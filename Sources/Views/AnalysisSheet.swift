//
//  AnalysisSheet.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import SwiftUI
import Charts

struct PlatformToolbarModifier: ViewModifier {
    let dismiss: DismissAction
    
    func body(content: Content) -> some View {
        #if os(macOS)
        content
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        #else
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        #endif
    }
}

struct AnalysisSheet: View {
    @Environment(\.dismiss) var dismiss
    let sequence: DNASequence
    
    @State private var selectedTab = 0
    @State private var gcWindowData: [(position: Int, gcContent: Double)] = []
    @State private var cpgIslands: [SequenceAnalyzer.CpGIsland] = []
    @State private var restrictionSites: [String: [RestrictionSite]] = [:]
    @State private var advancedRestrictionResults: [String: [RestrictionHit]] = [:]
    @State private var customSequence: String = ""
    @State private var isAnalyzing: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Analysis Type", selection: $selectedTab) {
                    Text("GC Content").tag(0)
                    Text("CpG Islands").tag(1)
                    Text("Restriction Sites").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                TabView(selection: $selectedTab) {
                    // GC Content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("GC Content Analysis")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Overall GC Content:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(String(format: "%.2f%%", sequence.gcContent))
                                        .fontWeight(.bold)
                                }
                                .padding(.horizontal)
                                
                                if !gcWindowData.isEmpty {
                                    Text("GC Content Window Plot")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    if #available(iOS 16.0, macOS 13.0, *) {
                                        Chart(gcWindowData, id: \.position) { data in
                                            LineMark(
                                                x: .value("Position", data.position),
                                                y: .value("GC%", data.gcContent)
                                            )
                                            .foregroundStyle(.blue)
                                        }
                                        .frame(height: 200)
                                        .padding()
                                    } else {
                                        // iOS 15 fallback: Simple list view
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Window samples (first 10):")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal)
                                            
                                            ForEach(gcWindowData.prefix(10), id: \.position) { data in
                                                HStack {
                                                    Text("Position \(data.position):")
                                                        .font(.caption)
                                                    Spacer()
                                                    Text(String(format: "%.2f%%", data.gcContent))
                                                        .font(.caption)
                                                        .fontWeight(.medium)
                                                }
                                                .padding(.horizontal)
                                                .padding(.vertical, 2)
                                            }
                                        }
                                        .padding(.vertical)
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    .tag(0)
                    
                    // CpG Islands
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("CpG Islands")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            if cpgIslands.isEmpty {
                                Text("No CpG islands found")
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                ForEach(Array(cpgIslands.enumerated()), id: \.offset) { index, island in
                                    CpGIslandCard(island: island, index: index + 1)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    .tag(1)
                    
                    // Advanced Restriction Sites
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Restriction Sites Analysis")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            // Sequence Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("DNA Sequence")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                TextEditor(text: $customSequence)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(minHeight: 120)
                                    .padding(8)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                                    .padding(.horizontal)
                                
                                HStack {
                                    Button {
                                        analyzeRestrictionSites()
                                    } label: {
                                        HStack {
                                            if isAnalyzing {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                            } else {
                                                Image(systemName: "scissors")
                                            }
                                            Text("Analyze")
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(isAnalyzing || customSequence.isEmpty)
                                    
                                    Spacer()
                                    
                                    Text("\(customSequence.count) bp")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal)
                            }
                            
                            // Results
                            if advancedRestrictionResults.isEmpty && !isAnalyzing {
                                VStack(spacing: 16) {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                        .font(.system(size: 60))
                                        .foregroundColor(.secondary)
                                    
                                    Text("Restriction Sites")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Text("Paste a DNA sequence and tap Analyze.")
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 24)
                            } else if isAnalyzing {
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                    Text("Analyzing restriction sites...")
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 24)
                            } else {
                                LazyVStack(spacing: 12) {
                                    // 결과를 효소 이름 알파벳 순으로 정렬
                                    ForEach(advancedRestrictionResults.sorted(by: { $0.key < $1.key }), id: \.key) { enzymeName, hits in
                                        if let firstHit = hits.first {
                                            AdvancedEnzymeRow(enzyme: firstHit.enzyme, hits: hits)
                                                .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    .tag(2)
                }
                #if !os(macOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
            }
            .navigationTitle("Analysis")
        }
        .modifier(PlatformToolbarModifier(dismiss: dismiss))
        .onAppear {
            performAnalysis()
        }
    }
    
    private func performAnalysis() {
        // GC Content Window Analysis
        gcWindowData = SequenceAnalyzer.calculateGCContentWindow(sequence.sequence, windowSize: 100)
        
        // CpG Island Finding
        cpgIslands = SequenceAnalyzer.findCpGIslands(sequence.sequence)
        
        // Restriction Site Finding
        restrictionSites = RestrictionEnzymes.shared.findAllSites(in: sequence.sequence)
        
        // Initialize custom sequence with current sequence
        customSequence = sequence.sequence
    }
    
    private func analyzeRestrictionSites() {
        isAnalyzing = true
        
        // 이전 결과 초기화
        advancedRestrictionResults = [:]
        
        DispatchQueue.global(qos: .userInitiated).async {
            // RestrictionEnzymes.shared에서 효소 목록 가져오기 (한 번만 로드됨)
            let enzymes = RestrictionEnzymes.shared.getAllEnzymes()
            let analyzer = RestrictionSiteAnalyzer()
            let results = analyzer.analyze(sequence: customSequence, enzymes: enzymes)
            
            DispatchQueue.main.async {
                advancedRestrictionResults = results
                isAnalyzing = false
                print("🔬 Analysis complete for '\(customSequence)' (\(customSequence.count)bp): Found \(results.count) enzymes with restriction sites")
            }
        }
    }
}

struct CpGIslandCard: View {
    let island: SequenceAnalyzer.CpGIsland
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CpG Island #\(index)")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Position: \(island.startPosition)-\(island.endPosition)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Length: \(island.length) bp")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("GC: \(String(format: "%.1f%%", island.gcContent))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("CpG Ratio: \(String(format: "%.2f", island.cpgRatio))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
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

struct RestrictionSiteCard: View {
    let enzyme: String
    let sites: [RestrictionSite]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(enzyme)
                    .font(.headline)
                
                Spacer()
                
                Text("\(sites.count) sites")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            
            if let enzyme = sites.first?.enzyme {
                HStack {
                    Text(enzyme.recognitionSite)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(enzyme.overhang)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(sites.prefix(10).enumerated()), id: \.offset) { _, site in
                        Text("\(site.position)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.3))
                            .cornerRadius(4)
                    }
                    
                    if sites.count > 10 {
                        Text("+\(sites.count - 10)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
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

// MARK: - Advanced Restriction Sites Components

struct AdvancedEnzymeRow: View {
    let enzyme: RestrictionEnzyme
    let hits: [RestrictionHit]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(enzyme.name).font(.headline)
                Spacer()
                Capsule()
                    .fill(Color.blue.opacity(0.15))
                    .overlay(
                        Text("\(hits.count) site\(hits.count > 1 ? "s" : "")")
                            .font(.caption).padding(.horizontal, 8)
                    )
                    .frame(height: 24)
            }

            HStack {
                Text(enzyme.recognitionSite).font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(enzyme.overhang).font(.caption).foregroundStyle(.secondary)
            }

            // 위치 칩 배지
            WrapHStack(spacing: 8) {
                ForEach(hits) { h in
                    Text("\(NumberFormatter.localizedString(from: h.position as NSNumber, number: .decimal))")
                        .font(.caption)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.green.opacity(0.18), in: Capsule())
                }
            }
        }
        .padding(.vertical, 6)
        #if os(macOS)
        .background(Color(NSColor.controlBackgroundColor))
        #else
        .background(Color(.systemGray6))
        #endif
        .cornerRadius(12)
    }
}

// 간단한 줄바꿈 HStack
struct WrapHStack<Content: View>: View {
    var spacing: CGFloat = 8
    @ViewBuilder var content: () -> Content

    var body: some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                content()
                    .alignmentGuide(.leading) { d in
                        if (abs(width - d.width) > geo.size.width) {
                            width = 0; height -= d.height + spacing
                        }
                        let result = width
                        if d.width != 0 { width -= d.width + spacing }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if height == 0 { height = 0 }
                        return result
                    }
            }
        }
        .frame(height: -height)
    }
}

#Preview {
    AnalysisSheet(sequence: DNASequence(
        name: "Sample",
        sequence: String(repeating: "ATGCGAATTCGCGATCGATCG", count: 10)
    ))
}

