//
//  SequenceDetailView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-22.
//

import SwiftUI

struct SequenceDetailView: View {
    @ObservedObject var viewModel: GeneViewModel
    let currentSequence: DNASequence?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Gene Information Display (All-in-One)
                geneInfoDisplay
                
                // Bottom padding to ensure content is not cut off
                Spacer(minLength: 50)
            }
            .padding(.horizontal)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Gene Information Display
    private var geneInfoDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(currentSequence?.name ?? "Gene") Information")
                    .font(.headline)
                
                Spacer()
                
                Text(currentSequence?.organism ?? "Genome")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let currentSequence = currentSequence {
                VStack(alignment: .leading, spacing: 6) {
                    // Gene basic info
                    InfoRow(label: "Gene Symbol", value: currentSequence.name)
                    
                    if let gene = viewModel.selectedGene {
                        InfoRow(label: "Full Name", value: gene.display_name)
                        if let desc = gene.description {
                            InfoRow(label: "Description", value: desc)
                        }
                    }
                    
                    InfoRow(label: "Chromosome", value: currentSequence.chromosome ?? "Unknown")
                    InfoRow(label: "Sequence Length", value: "\(currentSequence.sequence.count) bp")
                    InfoRow(label: "Organism", value: currentSequence.organism)
                    InfoRow(label: "Gene Type", value: currentSequence.geneType.rawValue)
                    InfoRow(label: "Strand", value: currentSequence.strand.rawValue)
                    
                    if let startPos = currentSequence.startPos, let endPos = currentSequence.endPos {
                        InfoRow(label: "Position", value: "\(startPos)-\(endPos)")
                    }
                    
                    if let accession = currentSequence.accession {
                        InfoRow(label: "Accession", value: accession)
                    }
                    
                    // Transcript information (from Ensembl API)
                    if let gene = viewModel.selectedGene {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Genomic Location:")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.indigo)
                            
                            InfoRow(label: "Chromosome", value: "Chr\(gene.chromosome)")
                            InfoRow(label: "Start Position", value: gene.start.formatted())
                            InfoRow(label: "End Position", value: gene.end.formatted())
                            InfoRow(label: "Gene Length", value: "\(gene.length.formatted()) bp")
                            InfoRow(label: "Strand", value: gene.strand == 1 ? "Forward (+)" : "Reverse (-)")
                        }
                    }
                    
                    // Transcript information
                    if !viewModel.transcripts.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Transcript Information:")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            
                            InfoRow(label: "Total Transcripts", value: "\(viewModel.transcripts.count) transcripts found")
                            
                            if let canonical = viewModel.transcripts.first(where: { $0.isCanonical }) {
                                InfoRow(label: "Canonical Transcript", value: canonical.id)
                                
                                if !viewModel.availableExons.isEmpty {
                                    InfoRow(label: "Total Exons", value: "\(viewModel.availableExons.count)")
                                    if let firstExon = viewModel.availableExons.first {
                                        InfoRow(label: "First Exon", value: firstExon.id)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Gene features
                    if !currentSequence.features.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Gene Features:")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            ForEach(currentSequence.features.prefix(3), id: \.startIndex) { feature in
                                Text(
                                    "• \(feature.type.rawValue): \(String(describing: feature.description))"
                                )
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Mutations info
                    if !currentSequence.mutations.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Key Mutations:")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            
                            ForEach(currentSequence.mutations.prefix(2), id: \.position) { mutation in
                                Text("• Position \(mutation.position): \(mutation.refBase)→\(mutation.altBase) (\(mutation.type.rawValue))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Disease links
                    if let diseaseLinks = currentSequence.diseaseLinks, !diseaseLinks.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Associated Diseases:")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            
                            Text(diseaseLinks.joined(separator: ", "))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Gene summary
                    if let summary = currentSequence.summary {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Gene Function:")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            
                            Text(summary)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Neighboring genes (if available from GenomeMap)
                    if !viewModel.neighboringGenes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Nearby Genes:")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.teal)
                            
                            ForEach(viewModel.neighboringGenes.prefix(5), id: \.id) { neighbor in
                                if neighbor.id != viewModel.selectedGene?.id {
                                    Text("• \(neighbor.display_name): Chr\(neighbor.chromosome)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(.red)
                    
                    Text("No gene information available")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text("Please load a DNA sequence first")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(8)
        .background(Color.blue.opacity(0.02))
        .cornerRadius(8)
    }
    
    // MARK: - Group Type Selector
    private var groupTypeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Group Type")
                .font(.headline)
            
            Picker("Group Type", selection: Binding(
                get: { viewModel.selectedGroupType },
                set: { newValue in
                    Task {
                        await viewModel.changeGroupType(newValue)
                    }
                }
            )) {
                ForEach(GroupType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    // MARK: - Additional Controls
    @ViewBuilder
    private var additionalControls: some View {
        switch viewModel.selectedGroupType {
        case .transcript:
            transcriptSelector
        case .exon:
            exonSelector
        case .region:
            regionSelector
        case .gene:
            EmptyView()
        }
    }
    
    private var transcriptSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transcript")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Picker("Transcript", selection: Binding(
                get: { viewModel.selectedTranscriptID ?? "" },
                set: { newValue in
                    Task {
                        await viewModel.selectTranscript(newValue)
                    }
                }
            )) {
                ForEach(viewModel.availableTranscripts, id: \.id) { transcript in
                    Text(transcript.display_name).tag(transcript.id)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    private var exonSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Exon")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Picker("Exon", selection: Binding(
                get: { viewModel.selectedExonIndex ?? 0 },
                set: { newValue in
                    Task {
                        await viewModel.selectExon(newValue)
                    }
                }
            )) {
                ForEach(Array(viewModel.availableExons.enumerated()), id: \.offset) { index, exon in
                    Text("Exon \(exon.rank)").tag(index)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    private var regionSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Region")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Start")
                        .font(.caption)
                    TextField("Start", value: Binding(
                        get: { viewModel.regionStart },
                        set: { newValue in
                            viewModel.regionStart = newValue
                            Task {
                                if let start = newValue, let end = viewModel.regionEnd {
                                    await viewModel.setRegion(start: start, end: end)
                                }
                            }
                        }
                    ), format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading) {
                    Text("End")
                        .font(.caption)
                    TextField("End", value: Binding(
                        get: { viewModel.regionEnd },
                        set: { newValue in
                            viewModel.regionEnd = newValue
                            Task {
                                if let start = viewModel.regionStart, let end = newValue {
                                    await viewModel.setRegion(start: start, end: end)
                                }
                            }
                        }
                    ), format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
        }
    }
    
    // MARK: - Sequence Display
    private var sequenceDisplay: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sequence (0-20 bp)")
                    .font(.headline)
                
                Spacer()
                
                Text("N=\(viewModel.sequenceLength) bp")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if viewModel.sequence20.isEmpty {
                Text("No sequence available")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                SequenceBoxView(sequence: viewModel.sequence20)
            }
        }
    }
}

#Preview {
    let viewModel = GeneViewModel()
    SequenceDetailView(viewModel: viewModel, currentSequence: nil)
        .padding()
}
