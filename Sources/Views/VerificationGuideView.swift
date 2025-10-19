//
//  VerificationGuideView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-18.
//

import SwiftUI

struct VerificationGuideView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 0
    @State private var isAnimating = false
    @State private var showResult = false
    
    private let totalSteps = 5
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Progress indicator
                ProgressView(value: Double(currentStep), total: Double(totalSteps))
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.horizontal)
                
                // Step content
                VStack(spacing: 20) {
                    switch currentStep {
                    case 0:
                        colonySelectionStep
                    case 1:
                        plasmidIsolationStep
                    case 2:
                        restrictionMappingStep
                    case 3:
                        pcrVerificationStep
                    case 4:
                        sequencingStep
                    default:
                        EmptyView()
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Navigation buttons
                HStack(spacing: 20) {
                    if currentStep > 0 {
                        Button("Previous") {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                currentStep -= 1
                                isAnimating = false
                                showResult = false
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    if currentStep < totalSteps - 1 {
                        Button("Next") {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                currentStep += 1
                                startCurrentStepAnimation()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Complete") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Verification Process")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Step Views
    
    private var colonySelectionStep: some View {
        VStack(spacing: 20) {
            Text("Step 1: Colony Selection")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Select colonies that grew on antibiotic plates:")
                    .font(.body)
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Colonies with recombinant DNA")
                }
                
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("Colonies without recombinant DNA")
                }
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.blue)
                    Text("Pick 3-5 individual colonies")
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
            
            // Colony visualization
            ColonySelectionView(isAnimating: isAnimating)
                .frame(height: 200)
        }
    }
    
    private var plasmidIsolationStep: some View {
        VStack(spacing: 20) {
            Text("Step 2: Plasmid Isolation")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Extract plasmids from selected colonies:")
                    .font(.body)
                
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.blue)
                    Text("Lyse bacterial cells")
                }
                
                HStack {
                    Image(systemName: "arrow.down")
                        .foregroundColor(.green)
                    Text("Separate plasmid from genomic DNA")
                }
                
                HStack {
                    Image(systemName: "drop.triangle")
                        .foregroundColor(.purple)
                    Text("Purify plasmid DNA")
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
            
            // Plasmid isolation visualization
            PlasmidIsolationView(isAnimating: isAnimating)
                .frame(height: 200)
        }
    }
    
    private var restrictionMappingStep: some View {
        VStack(spacing: 20) {
            Text("Step 3: Restriction Mapping")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Cut isolated plasmids with restriction enzymes:")
                    .font(.body)
                
                HStack {
                    Image(systemName: "scissors")
                        .foregroundColor(.red)
                    Text("Use same enzymes as cloning")
                }
                
                HStack {
                    Image(systemName: "rectangle.stack")
                        .foregroundColor(.blue)
                    Text("Run gel electrophoresis")
                }
                
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text("Verify correct fragment sizes")
                }
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(10)
            
            // Restriction mapping visualization
            RestrictionMappingView(isAnimating: isAnimating)
                .frame(height: 200)
        }
    }
    
    private var pcrVerificationStep: some View {
        VStack(spacing: 20) {
            Text("Step 4: PCR Verification")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Amplify specific regions of the plasmid:")
                    .font(.body)
                
                HStack {
                    Image(systemName: "thermometer")
                        .foregroundColor(.orange)
                    Text("Denaturation (94°C)")
                }
                
                HStack {
                    Image(systemName: "arrow.down")
                        .foregroundColor(.blue)
                    Text("Annealing (55-65°C)")
                }
                
                HStack {
                    Image(systemName: "arrow.up")
                        .foregroundColor(.green)
                    Text("Extension (72°C)")
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(10)
            
            // PCR visualization
            PCRVerificationView(isAnimating: isAnimating)
                .frame(height: 200)
        }
    }
    
    private var sequencingStep: some View {
        VStack(spacing: 20) {
            Text("Step 5: DNA Sequencing")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Determine the exact DNA sequence:")
                    .font(.body)
                
                HStack {
                    Image(systemName: "circle.hexagongrid.fill")
                        .foregroundColor(.blue)
                    Text("Sanger sequencing")
                }
                
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.green)
                    Text("Chromatogram analysis")
                }
                
                HStack {
                    Image(systemName: "checkmark.shield")
                        .foregroundColor(.purple)
                    Text("Final verification")
                }
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(10)
            
            // Sequencing visualization
            SequencingView(isAnimating: isAnimating, showResult: showResult)
                .frame(height: 200)
        }
    }
    
    private func startCurrentStepAnimation() {
        isAnimating = true
        
        // Show result after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showResult = true
            }
        }
    }
}

// MARK: - Supporting Views

struct ColonySelectionView: View {
    let isAnimating: Bool
    
    @State private var selectedColonies: [Bool] = Array(repeating: false, count: 8)
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Antibiotic Plate")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(selectedColonies[index] ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 1)
                        )
                        .scaleEffect(selectedColonies[index] ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: selectedColonies[index])
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            HStack {
                Text("Selected colonies")
                    .font(.caption)
                    .foregroundColor(.green)
                Spacer()
                Text("Unselected colonies")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            if isAnimating {
                selectRandomColonies()
            }
        }
        .onChange(of: isAnimating) { animating in
            if animating {
                selectRandomColonies()
            }
        }
    }
    
    private func selectRandomColonies() {
        // Randomly select 3-5 colonies
        let selectedCount = Int.random(in: 3...5)
        let indices = Array(0..<8).shuffled().prefix(selectedCount)
        
        for index in indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                selectedColonies[index] = true
            }
        }
    }
}

struct PlasmidIsolationView: View {
    let isAnimating: Bool
    
    @State private var showLysis = false
    @State private var showSeparation = false
    @State private var showPurification = false
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Plasmid Isolation Process")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                // Step 1: Lysis
                VStack {
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text("1")
                                .font(.headline)
                                .foregroundColor(.red)
                        )
                        .scaleEffect(showLysis ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.5), value: showLysis)
                    
                    Text("Lysis")
                        .font(.caption2)
                }
                
                // Step 2: Separation
                VStack {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text("2")
                                .font(.headline)
                                .foregroundColor(.blue)
                        )
                        .scaleEffect(showSeparation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.5), value: showSeparation)
                    
                    Text("Separation")
                        .font(.caption2)
                }
                
                // Step 3: Purification
                VStack {
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text("3")
                                .font(.headline)
                                .foregroundColor(.green)
                        )
                        .scaleEffect(showPurification ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.5), value: showPurification)
                    
                    Text("Purification")
                        .font(.caption2)
                }
            }
        }
        .onAppear {
            if isAnimating {
                startIsolationProcess()
            }
        }
        .onChange(of: isAnimating) { animating in
            if animating {
                startIsolationProcess()
            }
        }
    }
    
    private func startIsolationProcess() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showLysis = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showSeparation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showPurification = true
        }
    }
}

struct RestrictionMappingView: View {
    let isAnimating: Bool
    
    @State private var showCutting = false
    @State private var showElectrophoresis = false
    @State private var showBands = false
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Restriction Mapping")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 30) {
                // Plasmid
                VStack {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text("Plasmid")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        )
                        .scaleEffect(showCutting ? 0.8 : 1.0)
                        .animation(.easeInOut(duration: 0.5), value: showCutting)
                }
                
                // Arrow
                Image(systemName: "arrow.right")
                    .foregroundColor(.gray)
                
                // Gel electrophoresis
                VStack {
                    Rectangle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 40, height: 80)
                        .overlay(
                            VStack {
                                if showBands {
                                    ForEach(0..<3, id: \.self) { index in
                                        Rectangle()
                                            .fill(Color.green)
                                            .frame(width: 30, height: 8)
                                            .offset(y: CGFloat(index * 15 - 15))
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                            }
                        )
                        .cornerRadius(5)
                        .scaleEffect(showElectrophoresis ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.5), value: showElectrophoresis)
                }
            }
        }
        .onAppear {
            if isAnimating {
                startRestrictionMapping()
            }
        }
        .onChange(of: isAnimating) { animating in
            if animating {
                startRestrictionMapping()
            }
        }
    }
    
    private func startRestrictionMapping() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showCutting = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showElectrophoresis = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showBands = true
            }
        }
    }
}

struct PCRVerificationView: View {
    let isAnimating: Bool
    
    @State private var currentTemperature: Double = 94
    @State private var cycleCount = 0
    
    var body: some View {
        VStack(spacing: 15) {
            Text("PCR Cycling")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 10) {
                Text("Temperature: \(Int(currentTemperature))°C")
                    .font(.headline)
                    .foregroundColor(currentTemperature > 70 ? .red : currentTemperature > 50 ? .orange : .blue)
                
                Text("Cycle: \(cycleCount)/30")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ProgressView(value: Double(cycleCount), total: 30)
                    .progressViewStyle(LinearProgressViewStyle())
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // DNA amplification visualization
            HStack(spacing: 20) {
                ForEach(0..<min(cycleCount + 1, 8), id: \.self) { index in
                    Circle()
                        .fill(Color.green.opacity(0.7))
                        .frame(width: 20, height: 20)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isAnimating)
                }
            }
        }
        .onAppear {
            if isAnimating {
                startPCR()
            }
        }
        .onChange(of: isAnimating) { animating in
            if animating {
                startPCR()
            }
        }
    }
    
    private func startPCR() {
        // Simulate PCR cycles
        for cycle in 1...30 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(cycle) * 0.1) {
                // Denaturation
                currentTemperature = 94
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // Annealing
                    currentTemperature = 55
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        // Extension
                        currentTemperature = 72
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            cycleCount = cycle
                        }
                    }
                }
            }
        }
    }
}

struct SequencingView: View {
    let isAnimating: Bool
    let showResult: Bool
    
    @State private var showSequence = false
    
    private let sequence = "ATCGATCGATCG"
    
    var body: some View {
        VStack(spacing: 15) {
            Text("DNA Sequencing")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if showResult {
                VStack(spacing: 10) {
                    Text("Sequenced DNA:")
                        .font(.headline)
                    
                    Text(sequence)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(5)
                    
                    Text("✓ Sequence matches expected result")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                VStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(), value: isAnimating)
                    
                    Text("Analyzing sequence...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            if isAnimating {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showSequence = true
                }
            }
        }
    }
}

#Preview {
    VerificationGuideView()
}
