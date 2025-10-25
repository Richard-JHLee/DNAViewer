//
//  GelElectrophoresisView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-18.
//

import SwiftUI

struct GelElectrophoresisView: View {
    let fragments: [DNAFragment]
    let enzymes: [RestrictionEnzyme]
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 0
    @State private var isAnimating = false
    @State private var showResults = false
    @State private var showAllFragments = false
    
    private let totalSteps = 4
    
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
                        gelPreparationStep
                    case 1:
                        sampleLoadingStep
                    case 2:
                        electrophoresisStep
                    case 3:
                        resultsStep
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
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    if currentStep < totalSteps - 1 {
                        Button(currentStep == 2 ? "Run Electrophoresis" : "Next") {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                currentStep += 1
                                if currentStep == 3 {
                                    startElectrophoresisAnimation()
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Gel Electrophoresis")
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
    
    private var gelPreparationStep: some View {
        VStack(spacing: 20) {
            Text("Step 1: Gel Preparation")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.blue)
                    Text("Agarose gel (0.8-2%) preparation")
                }
                
                HStack {
                    Image(systemName: "thermometer")
                        .foregroundColor(.orange)
                    Text("Heat to dissolve agarose")
                }
                
                HStack {
                    Image(systemName: "drop.triangle")
                        .foregroundColor(.purple)
                    Text("Add ethidium bromide (DNA stain)")
                }
                
                HStack {
                    Image(systemName: "hourglass")
                        .foregroundColor(.gray)
                    Text("Allow gel to solidify")
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
            
            Image(systemName: "rectangle.stack")
                .font(.system(size: 80))
                .foregroundColor(.blue.opacity(0.7))
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(), value: isAnimating)
                .onAppear {
                    isAnimating = true
                }
        }
    }
    
    private var sampleLoadingStep: some View {
        VStack(spacing: 20) {
            Text("Step 2: Sample Loading")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Loading wells with:")
                    .font(.headline)
                
                ForEach(Array(fragments.enumerated()), id: \.offset) { index, fragment in
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                        Text("Fragment \(index + 1): \(fragment.length) bp")
                            .font(.body)
                    }
                }
                
                HStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)
                    Text("DNA Ladder (size marker)")
                        .font(.body)
                }
                
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                    Text("Loading dye")
                        .font(.body)
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
            
            // Gel visualization
            GelLoadingView(fragments: fragments, isAnimating: isAnimating)
                .frame(height: 200)
        }
    }
    
    private var electrophoresisStep: some View {
        VStack(spacing: 20) {
            Text("Step 3: Electrophoresis")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                    Text("Apply voltage: 80-120V")
                }
                
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)
                    Text("Run time: 30-60 minutes")
                }
                
                HStack {
                    Image(systemName: "arrow.down")
                        .foregroundColor(.blue)
                    Text("DNA moves toward positive electrode")
                }
                
                HStack {
                    Image(systemName: "ruler")
                        .foregroundColor(.purple)
                    Text("Smaller fragments move faster")
                }
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(10)
            
            // Running electrophoresis animation
            ElectrophoresisRunningView(fragments: fragments, isRunning: isAnimating)
                .frame(height: 250)
        }
    }
    
    private var resultsStep: some View {
        VStack(spacing: 20) {
            Text("Step 4: Results")
                .font(.title2)
                .bold()
            
            Text("Gel electrophoresis completed!")
                .font(.headline)
                .foregroundColor(.green)
            
            // Results visualization
            GelResultsView(fragments: fragments)
                .frame(height: 300)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Analysis Summary:")
                    .font(.headline)
                
                // Summary statistics
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Fragments:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(fragments.count)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Size Range:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(minFragmentSize)-\(maxFragmentSize) bp")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Average Size:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(averageFragmentSize) bp")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
                .padding(.bottom, 8)
                
                Divider()
                
                // Top 5 largest fragments
                Text("Largest Fragments (Top 5):")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                ForEach(Array(sortedFragments.prefix(5).enumerated()), id: \.offset) { index, fragment in
                    HStack {
                        Text("Fragment \(fragmentIndex(fragment)):")
                            .font(.caption)
                        Spacer()
                        Text("\(fragment.length) bp")
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
                
                // View All button
                if fragments.count > 5 {
                    Button(action: {
                        showAllFragments = true
                    }) {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("View All \(fragments.count) Fragments")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .sheet(isPresented: $showAllFragments) {
                allFragmentsSheet
            }
        }
    }
    
    private func startElectrophoresisAnimation() {
        isAnimating = true
        
        // Simulate electrophoresis running time
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showResults = true
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var sortedFragments: [DNAFragment] {
        fragments.sorted { $0.length > $1.length }
    }
    
    private var minFragmentSize: Int {
        fragments.map { $0.length }.min() ?? 0
    }
    
    private var maxFragmentSize: Int {
        fragments.map { $0.length }.max() ?? 0
    }
    
    private var averageFragmentSize: Int {
        guard !fragments.isEmpty else { return 0 }
        let total = fragments.reduce(0) { $0 + $1.length }
        return total / fragments.count
    }
    
    private func fragmentIndex(_ fragment: DNAFragment) -> Int {
        (fragments.firstIndex { $0.start == fragment.start && $0.end == fragment.end } ?? 0) + 1
    }
    
    // MARK: - All Fragments Sheet
    
    private var allFragmentsSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(fragments.enumerated()), id: \.offset) { index, fragment in
                        HStack {
                            Text("Fragment \(index + 1):")
                                .font(.body)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(fragment.length) bp")
                                    .fontWeight(.semibold)
                                Text("Position: \(fragment.start)-\(fragment.end)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("All Fragments (\(fragments.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showAllFragments = false
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct GelLoadingView: View {
    let fragments: [DNAFragment]
    let isAnimating: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Gel Wells")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 15) {
                // Wells
                ForEach(0..<(fragments.count + 2), id: \.self) { index in
                    VStack(spacing: 5) {
                        Rectangle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 30, height: 20)
                            .cornerRadius(3)
                        
                        if index < fragments.count {
                            Text("\(fragments[index].length)")
                                .font(.caption2)
                        } else if index == fragments.count {
                            Text("Ladder")
                                .font(.caption2)
                        } else {
                            Text("Dye")
                                .font(.caption2)
                        }
                    }
                }
            }
            
            // Gel base
            Rectangle()
                .fill(Color.blue.opacity(0.1))
                .frame(height: 100)
                .cornerRadius(5)
        }
        .padding()
    }
}

struct ElectrophoresisRunningView: View {
    let fragments: [DNAFragment]
    let isRunning: Bool
    
    @State private var fragmentPositions: [CGFloat] = []
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Electrophoresis in Progress")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            ZStack {
                // Gel
                Rectangle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(height: 150)
                    .cornerRadius(5)
                
                // DNA fragments moving
                HStack(spacing: 15) {
                    ForEach(Array(fragments.enumerated()), id: \.offset) { index, fragment in
                        VStack {
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: 20, height: min(CGFloat(fragment.length / 25), 40))
                                .cornerRadius(2)
                                .offset(y: fragmentPositions.indices.contains(index) ? fragmentPositions[index] : 0)
                                .animation(.linear(duration: 3.0), value: fragmentPositions.indices.contains(index) ? fragmentPositions[index] : 0)
                        }
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Image(systemName: "minus")
                    .foregroundColor(.red)
                Spacer()
                Text("DNA fragments")
                    .font(.caption)
                Spacer()
                Image(systemName: "plus")
                    .foregroundColor(.black)
            }
            .padding(.horizontal)
        }
        .frame(height: 250)
        .padding()
        .onAppear {
            if isRunning {
                startElectrophoresis()
            }
        }
        .onChange(of: isRunning) { running in
            if running {
                startElectrophoresis()
            }
        }
    }
    
    private func startElectrophoresis() {
        fragmentPositions = []
        fragmentPositions = fragments.enumerated().map { index, fragment in
            // Smaller fragments move faster (more negative offset)
            return CGFloat(-fragment.length / 5) - CGFloat(index * 10)
        }
    }
}

struct GelResultsView: View {
    let fragments: [DNAFragment]
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Gel Electrophoresis Results")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: true) {
                ZStack {
                    // Gel
                    Rectangle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: max(CGFloat(fragments.count * 40), 300), height: 200)
                        .cornerRadius(5)
                    
                    // DNA bands in lanes
                    HStack(spacing: 15) {
                        ForEach(Array(fragments.enumerated()), id: \.offset) { index, fragment in
                            VStack {
                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: 20, height: min(CGFloat(fragment.length / 15), 50))
                                    .cornerRadius(2)
                                    .offset(y: CGFloat(-fragment.length / 5) - CGFloat(index * 15))
                                
                                Text("\(fragment.length)")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                
                                Text("#\(index + 1)")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .frame(height: 220)
            
            HStack {
                Image(systemName: "arrow.up")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Smaller fragments migrate further")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Scroll for more →")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .opacity(fragments.count > 7 ? 1.0 : 0.0)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    GelElectrophoresisView(
        fragments: [
            DNAFragment(sequence: "ATCG", start: 0, end: 4),
            DNAFragment(sequence: "GCTA", start: 4, end: 8),
            DNAFragment(sequence: "TTAA", start: 8, end: 12)
        ],
        enzymes: []
    )
}
