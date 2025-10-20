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
    @State private var showAllCodons: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Analysis Type", selection: $selectedTab) {
                    Text("GC Content").tag(0)
                    Text("CpG Islands").tag(1)
                    Text("Restriction Sites").tag(2)
                    Text("Protein").tag(3)
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
                    
                    // Protein Translation (embedded from TranslationSheet)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("단백질 번역 (Protein Translation)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            // Frame Selector
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Reading Frame")
                                    .font(.headline)
                                
                                Picker("Frame", selection: $selectedTab) {
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
                                    Text(String(sequence.sequence.prefix(300)))
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
                                
                                let codons = CodonTable.shared.translateSequence(sequence.sequence)
                                let aminoAcids = codons.map { $0.aminoAcid }.joined(separator: " ")
                                
                                ScrollView(.horizontal, showsIndicators: true) {
                                    Text(aminoAcids)
                                        .font(.system(.title3, design: .monospaced))
                                        .padding()
                                        #if os(macOS)
                                        .background(Color(NSColor.controlBackgroundColor))
                                        #else
                                        .background(Color(.systemGray6))
                                        #endif
                                        .cornerRadius(8)
                                }
                                
                                Text("\(codons.count) amino acids")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            
                            // Amino Acid Composition
                            VStack(alignment: .leading, spacing: 12) {
                                Text("아미노산 조성 (Amino Acid Composition)")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                let codons = CodonTable.shared.translateSequence(sequence.sequence)
                                let composition = getAminoAcidComposition(codons: codons)
                                let maxCount = composition.values.max() ?? 1
                                
                                VStack(spacing: 8) {
                                    ForEach(composition.sorted(by: { $0.value > $1.value }), id: \.key) { aminoAcid, count in
                                        HStack(spacing: 12) {
                                            // Amino acid label
                                            Text(aminoAcid)
                                                .font(.system(.body, design: .monospaced))
                                                .fontWeight(.bold)
                                                .frame(width: 30, alignment: .leading)
                                            
                                            // Bar chart
                                            GeometryReader { geometry in
                                                ZStack(alignment: .leading) {
                                                    // Background bar
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(Color.gray.opacity(0.2))
                                                        .frame(height: 24)
                                                    
                                                    // Filled bar
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(
                                                            LinearGradient(
                                                                gradient: Gradient(colors: [
                                                                    getAminoAcidColor(aminoAcid),
                                                                    getAminoAcidColor(aminoAcid).opacity(0.7)
                                                                ]),
                                                                startPoint: .leading,
                                                                endPoint: .trailing
                                                            )
                                                        )
                                                        .frame(width: geometry.size.width * CGFloat(count) / CGFloat(maxCount), height: 24)
                                                }
                                            }
                                            .frame(height: 24)
                                            
                                            // Count and percentage
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text("\(count)")
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                
                                                Text(String(format: "%.1f%%", Double(count) * 100.0 / Double(codons.count)))
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(width: 50, alignment: .trailing)
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical)
                            
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
                                        ORFDisplayCard(orf: orf, index: index + 1)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            // Codon Table Details
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("코돈 번역 상세")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    if !showAllCodons {
                                        Button(action: {
                                            withAnimation {
                                                showAllCodons = true
                                            }
                                        }) {
                                            HStack(spacing: 4) {
                                                Text("Show All")
                                                Image(systemName: "chevron.down.circle")
                                            }
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        }
                                    } else {
                                        Button(action: {
                                            withAnimation {
                                                showAllCodons = false
                                            }
                                        }) {
                                            HStack(spacing: 4) {
                                                Text("Show Less")
                                                Image(systemName: "chevron.up.circle")
                                            }
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                
                                let codons = CodonTable.shared.translateSequence(sequence.sequence)
                                let displayCount = showAllCodons ? codons.count : min(20, codons.count)
                                
                                LazyVStack(spacing: 4) {
                                    ForEach(Array(codons.prefix(displayCount).enumerated()), id: \.offset) { index, codon in
                                        HStack(spacing: 12) {
                                            Text("\(index * 3 + 1)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .frame(width: 40, alignment: .trailing)
                                            
                                            Text(codon.sequence)
                                                .font(.system(.body, design: .monospaced))
                                                .fontWeight(.semibold)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(codon.isStartCodon ? Color.green.opacity(0.2) : codon.isStopCodon ? Color.red.opacity(0.2) : Color.blue.opacity(0.1))
                                                .cornerRadius(6)
                                            
                                            Image(systemName: "arrow.right")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            HStack(spacing: 4) {
                                                Text(codon.aminoAcid)
                                                    .font(.system(.body, design: .monospaced))
                                                    .fontWeight(.bold)
                                                
                                                if codon.isStartCodon {
                                                    Text("START")
                                                        .font(.system(size: 9, weight: .bold))
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.green)
                                                        .cornerRadius(4)
                                                } else if codon.isStopCodon {
                                                    Text("STOP")
                                                        .font(.system(size: 9, weight: .bold))
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.red)
                                                        .cornerRadius(4)
                                                }
                                            }
                                            
                                            Spacer()
                                            
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
                                    
                                    if !showAllCodons && codons.count > 20 {
                                        Button(action: {
                                            withAnimation {
                                                showAllCodons = true
                                            }
                                        }) {
                                            HStack {
                                                Spacer()
                                                VStack(spacing: 8) {
                                                    Text("Show \(codons.count - 20) more codons")
                                                        .font(.subheadline)
                                                        .fontWeight(.semibold)
                                                    
                                                    HStack(spacing: 4) {
                                                        Text("Tap to expand")
                                                            .font(.caption)
                                                        Image(systemName: "arrow.down.circle.fill")
                                                            .font(.caption)
                                                    }
                                                    .foregroundColor(.secondary)
                                                }
                                                .foregroundColor(.blue)
                                                .padding()
                                                Spacer()
                                            }
                                            #if os(macOS)
                                            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                            #else
                                            .background(Color(.systemGray6).opacity(0.5))
                                            #endif
                                            .cornerRadius(12)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .tag(3)
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
    
    // MARK: - Amino Acid Composition Helper
    
    private func getAminoAcidComposition(codons: [Codon]) -> [String: Int] {
        var composition: [String: Int] = [:]
        
        for codon in codons {
            let aa = codon.aminoAcid
            // Skip stop codons
            if aa != "*" {
                composition[aa, default: 0] += 1
            }
        }
        
        return composition
    }
    
    private func getAminoAcidColor(_ aminoAcid: String) -> Color {
        // Color coding based on amino acid properties
        switch aminoAcid {
        // Hydrophobic (파란색 계열)
        case "A", "V", "I", "L", "M", "F", "W", "P":
            return Color.blue
        // Polar (초록색 계열)
        case "S", "T", "C", "Y", "N", "Q":
            return Color.green
        // Positively charged (빨간색 계열)
        case "K", "R", "H":
            return Color.red
        // Negatively charged (주황색 계열)
        case "D", "E":
            return Color.orange
        // Special (보라색)
        case "G":
            return Color.purple
        default:
            return Color.gray
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

// MARK: - ORF Display Card for Analysis Sheet

struct ORFDisplayCard: View {
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

