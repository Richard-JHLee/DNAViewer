//
//  TransformationAnimationView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-18.
//

import SwiftUI

struct TransformationAnimationView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var currentMethod = 0
    @State private var isAnimating = false
    @State private var showResult = false
    
    private let methods = ["Heat Shock", "Electroporation", "Chemical Transformation"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                // Method selection
                Picker("Transformation Method", selection: $currentMethod) {
                    ForEach(0..<methods.count, id: \.self) { index in
                        Text(methods[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Animation area
                ScrollView {
                    VStack(spacing: 25) {
                        Text(methods[currentMethod])
                            .font(.title2)
                            .bold()
                        
                        switch currentMethod {
                        case 0:
                            HeatShockView(isAnimating: isAnimating)
                        case 1:
                            ElectroporationView(isAnimating: isAnimating)
                        case 2:
                            ChemicalTransformationView(isAnimating: isAnimating)
                        default:
                            EmptyView()
                        }
                        
                        if showResult {
                            TransformationResultView()
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.bottom, 15)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Control buttons
                HStack(spacing: 16) {
                    Button("Start Animation") {
                        startTransformation()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isAnimating)
                    
                    Button("Reset") {
                        resetAnimation()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("Transformation Process")
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
    
    private func startTransformation() {
        isAnimating = true
        showResult = false
        
        // Simulate transformation process
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showResult = true
            }
        }
    }
    
    private func resetAnimation() {
        isAnimating = false
        showResult = false
    }
}

// MARK: - Heat Shock View

struct HeatShockView: View {
    let isAnimating: Bool
    
    @State private var temperature: Double = 37
    @State private var showHeat = false
    @State private var showCold = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Temperature display
            VStack {
                Text("Temperature: \(Int(temperature))°C")
                    .font(.headline)
                    .foregroundColor(temperature > 37 ? .red : temperature < 37 ? .blue : .green)
                
                ProgressView(value: temperature, total: 100)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(temperature > 37 ? .red : temperature < 37 ? .blue : .green)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // Cell and DNA visualization
            HStack(spacing: 40) {
                // Bacterial cell
                VStack {
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(Color.green, lineWidth: 2)
                        )
                        .overlay(
                            Text("E. coli")
                                .font(.caption)
                                .foregroundColor(.green)
                        )
                        .scaleEffect(showHeat ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.5), value: showHeat)
                    
                    Text("Bacterial Cell")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // DNA plasmid
                VStack {
                    Circle()
                        .fill(Color.blue.opacity(0.7))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text("DNA")
                                .font(.caption)
                                .foregroundColor(.white)
                        )
                        .scaleEffect(showCold ? 0.8 : 1.0)
                        .animation(.easeInOut(duration: 0.5), value: showCold)
                    
                    Text("Plasmid")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Process description
            VStack(alignment: .leading, spacing: 10) {
                Text("Heat Shock Process:")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "thermometer.sun")
                        .foregroundColor(.red)
                    Text("1. Heat to 42°C (membranes become permeable)")
                }
                
                HStack {
                    Image(systemName: "arrow.down")
                        .foregroundColor(.blue)
                    Text("2. Cool to 0°C (DNA enters cell)")
                }
                
                HStack {
                    Image(systemName: "arrow.up")
                        .foregroundColor(.green)
                    Text("3. Return to 37°C (recovery)")
                }
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(10)
        }
        .onAppear {
            if isAnimating {
                startHeatShock()
            }
        }
        .onChange(of: isAnimating) { animating in
            if animating {
                startHeatShock()
            }
        }
    }
    
    private func startHeatShock() {
        // Heat phase
        withAnimation(.easeInOut(duration: 1.0)) {
            temperature = 42
            showHeat = true
        }
        
        // Cold phase
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 1.0)) {
                temperature = 0
                showCold = true
                showHeat = false
            }
        }
        
        // Recovery phase
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 1.0)) {
                temperature = 37
                showCold = false
            }
        }
    }
}

// MARK: - Electroporation View

struct ElectroporationView: View {
    let isAnimating: Bool
    
    @State private var showElectricField = false
    @State private var showPores = false
    @State private var showDNAEntry = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Electric field visualization
            VStack {
                Text("Electric Field")
                    .font(.headline)
                
                ZStack {
                    // Cell membrane
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(Color.green, lineWidth: 3)
                        )
                    
                    // Electric field lines
                    if showElectricField {
                        ForEach(0..<8, id: \.self) { index in
                            Path { path in
                                let angle = Double(index) * .pi / 4
                                let startX = 60 + cos(angle) * 40
                                let startY = 60 + sin(angle) * 40
                                let endX = 60 + cos(angle) * 80
                                let endY = 60 + sin(angle) * 80
                                
                                path.move(to: CGPoint(x: startX, y: startY))
                                path.addLine(to: CGPoint(x: endX, y: endY))
                            }
                            .stroke(Color.yellow, lineWidth: 2)
                            .animation(.easeInOut(duration: 0.5).delay(Double(index) * 0.1), value: showElectricField)
                        }
                    }
                    
                    // Membrane pores
                    if showPores {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(
                                    x: CGFloat.random(in: -30...30),
                                    y: CGFloat.random(in: -30...30)
                                )
                                .animation(.easeInOut(duration: 0.3), value: showPores)
                        }
                    }
                    
                    // DNA entering
                    if showDNAEntry {
                        ForEach(0..<2, id: \.self) { index in
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 6, height: 6)
                                .offset(
                                    x: CGFloat.random(in: -40...40),
                                    y: CGFloat.random(in: -40...40)
                                )
                                .animation(.easeInOut(duration: 0.5), value: showDNAEntry)
                        }
                    }
                }
            }
            
            // Process description
            VStack(alignment: .leading, spacing: 10) {
                Text("Electroporation Process:")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                    Text("1. Apply electric pulse (creates pores in membrane)")
                }
                
                HStack {
                    Image(systemName: "arrow.down")
                        .foregroundColor(.blue)
                    Text("2. DNA enters through pores")
                }
                
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text("3. Membrane reseals")
                }
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(10)
        }
        .onAppear {
            if isAnimating {
                startElectroporation()
            }
        }
        .onChange(of: isAnimating) { animating in
            if animating {
                startElectroporation()
            }
        }
    }
    
    private func startElectroporation() {
        // Electric field
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showElectricField = true
        }
        
        // Pores formation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showPores = true
        }
        
        // DNA entry
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showDNAEntry = true
        }
        
        // Reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            showElectricField = false
            showPores = false
            showDNAEntry = false
        }
    }
}

// MARK: - Chemical Transformation View

struct ChemicalTransformationView: View {
    let isAnimating: Bool
    
    @State private var showChemicals = false
    @State private var showMixing = false
    @State private var showTransformation = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Chemical mixture visualization
            VStack {
                Text("Chemical Treatment")
                    .font(.headline)
                
                ZStack {
                    // Container
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 2)
                        )
                    
                    // Chemicals
                    if showChemicals {
                        VStack(spacing: 10) {
                            // Calcium chloride
                            Circle()
                                .fill(Color.blue.opacity(0.7))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Text("Ca²⁺")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                )
                            
                            // DNA
                            Circle()
                                .fill(Color.green.opacity(0.7))
                                .frame(width: 25, height: 25)
                                .overlay(
                                    Text("DNA")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                )
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Mixing animation
                    if showMixing {
                        ForEach(0..<6, id: \.self) { index in
                            Circle()
                                .fill(Color.orange.opacity(0.5))
                                .frame(width: 8, height: 8)
                                .offset(
                                    x: CGFloat.random(in: -80...80),
                                    y: CGFloat.random(in: -60...60)
                                )
                                .animation(.easeInOut(duration: 1.0).repeatForever(), value: showMixing)
                        }
                    }
                }
            }
            
            // Process description
            VStack(alignment: .leading, spacing: 10) {
                Text("Chemical Transformation:")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.blue)
                    Text("1. CaCl₂ makes cells competent")
                }
                
                HStack {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.orange)
                    Text("2. Mix with DNA")
                }
                
                HStack {
                    Image(systemName: "arrow.down")
                        .foregroundColor(.green)
                    Text("3. DNA enters cells")
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
        .onAppear {
            if isAnimating {
                startChemicalTransformation()
            }
        }
        .onChange(of: isAnimating) { animating in
            if animating {
                startChemicalTransformation()
            }
        }
    }
    
    private func startChemicalTransformation() {
        // Show chemicals
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showChemicals = true
            }
        }
        
        // Start mixing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showMixing = true
        }
        
        // Transformation complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showMixing = false
            showTransformation = true
        }
    }
}

// MARK: - Transformation Result View

struct TransformationResultView: View {
    @State private var showSuccess = false
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Transformation Result")
                .font(.headline)
            
            HStack(spacing: 30) {
                // Successful transformants
                VStack {
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                                .font(.title)
                        )
                        .scaleEffect(showSuccess ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.5), value: showSuccess)
                    
                    Text("Success")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                    
                    Text("Cells with recombinant DNA")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                }
                
                // Failed transformants
                VStack {
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "xmark")
                                .foregroundColor(.red)
                                .font(.title)
                        )
                    
                    Text("Failed")
                        .font(.caption)
                        .foregroundColor(.red)
                        .fontWeight(.semibold)
                    
                    Text("Cells without recombinant DNA")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                }
            }
            
            Text("Next: Antibiotic selection to identify successful transformants")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showSuccess = true
            }
        }
    }
}

#Preview {
    TransformationAnimationView()
}
