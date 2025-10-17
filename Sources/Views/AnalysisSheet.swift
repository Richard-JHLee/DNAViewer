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
                    
                    // Restriction Sites
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Restriction Sites")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            if restrictionSites.isEmpty {
                                Text("No restriction sites found")
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                ForEach(restrictionSites.sorted(by: { $0.key < $1.key }), id: \.key) { enzyme, sites in
                                    RestrictionSiteCard(enzyme: enzyme, sites: sites)
                                        .padding(.horizontal)
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

#Preview {
    AnalysisSheet(sequence: DNASequence(
        name: "Sample",
        sequence: String(repeating: "ATGCGAATTCGCGATCGATCG", count: 10)
    ))
}

