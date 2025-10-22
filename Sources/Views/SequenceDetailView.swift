//
//  SequenceDetailView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-22.
//

import SwiftUI

struct SequenceDetailView: View {
    @ObservedObject var viewModel: GeneViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Group Type Selector
            groupTypeSelector
            
            // Additional Controls
            additionalControls
            
            // Sequence Display
            sequenceDisplay
            
            Spacer()
        }
        .padding()
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
    return SequenceDetailView(viewModel: viewModel)
        .padding()
}
