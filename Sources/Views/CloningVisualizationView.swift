//
//  CloningVisualizationView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-18.
//

import SwiftUI
import SceneKit

struct CloningVisualizationView: View {
    let targetDNA: DNAFragment
    let vectorDNA: DNAFragment
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 0
    @State private var isAnimating = false
    @State private var show3D = false
    
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
                        preparationStep
                    case 1:
                        cuttingStep
                    case 2:
                        ligationStep
                    case 3:
                        transformationStep
                    case 4:
                        selectionStep
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
                        Button("Next") {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                currentStep += 1
                                if currentStep == 2 {
                                    startLigationAnimation()
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
            .navigationTitle("DNA Cloning Process")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("3D View") {
                        show3D.toggle()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $show3D) {
            Cloning3DView(targetDNA: targetDNA, vectorDNA: vectorDNA)
        }
    }
    
    // MARK: - Step Views
    
    private var preparationStep: some View {
        VStack(spacing: 20) {
            Text("Step 1: Preparation")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Materials needed:")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "circle.hexagongrid.fill")
                        .foregroundColor(.blue)
                    Text("Target DNA fragment")
                }
                
                HStack {
                    Image(systemName: "circle.hexagongrid")
                        .foregroundColor(.green)
                    Text("Vector DNA (plasmid)")
                }
                
                HStack {
                    Image(systemName: "scissors")
                        .foregroundColor(.red)
                    Text("Restriction enzymes")
                }
                
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(.purple)
                    Text("DNA ligase")
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
            
            // DNA visualization
            DNAPreparationView(targetDNA: targetDNA, vectorDNA: vectorDNA)
                .frame(height: 200)
        }
    }
    
    private var cuttingStep: some View {
        VStack(spacing: 20) {
            Text("Step 2: Cutting with Restriction Enzymes")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Both target DNA and vector are cut with the same restriction enzyme:")
                    .font(.body)
                
                HStack {
                    Image(systemName: "scissors")
                        .foregroundColor(.red)
                    Text("Creates compatible sticky ends")
                }
                
                HStack {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(.blue)
                    Text("Allows specific base pairing")
                }
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(10)
            
            // Cutting animation
            DNACuttingView(targetDNA: targetDNA, vectorDNA: vectorDNA)
                .frame(height: 250)
        }
    }
    
    private var ligationStep: some View {
        VStack(spacing: 20) {
            Text("Step 3: Ligation")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 15) {
                Text("DNA ligase joins the fragments:")
                    .font(.body)
                
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(.purple)
                    Text("Forms phosphodiester bonds")
                }
                
                HStack {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.green)
                    Text("Creates recombinant DNA")
                }
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(10)
            
            // Ligation animation
            LigaseActionView()
                .frame(height: 250)
        }
    }
    
    private var transformationStep: some View {
        VStack(spacing: 20) {
            Text("Step 4: Transformation")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Recombinant DNA is introduced into host cells:")
                    .font(.body)
                
                HStack {
                    Image(systemName: "circle.hexagongrid.fill")
                        .foregroundColor(.green)
                    Text("E. coli cells are commonly used")
                }
                
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                    Text("Heat shock or electroporation")
                }
                
                HStack {
                    Image(systemName: "arrow.down")
                        .foregroundColor(.blue)
                    Text("DNA enters the cell")
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
            
            // Transformation animation
            TransformationView()
                .frame(height: 250)
        }
    }
    
    private var selectionStep: some View {
        VStack(spacing: 20) {
            Text("Step 5: Selection")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Only cells with the recombinant DNA survive:")
                    .font(.body)
                
                HStack {
                    Image(systemName: "pills.fill")
                        .foregroundColor(.red)
                    Text("Antibiotic resistance gene")
                }
                
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text("Successful transformants grow")
                }
                
                HStack {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.red)
                    Text("Non-transformants die")
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(10)
            
            // Selection visualization
            SelectionView()
                .frame(height: 250)
        }
    }
    
    private func startLigationAnimation() {
        isAnimating = true
    }
}

// MARK: - Supporting Views

struct DNAPreparationView: View {
    let targetDNA: DNAFragment
    let vectorDNA: DNAFragment
    @State private var isAnimating: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 30) {
                // Target DNA
                VStack {
                    Text("Target DNA")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 80, height: 20)
                        .cornerRadius(5)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(), value: isAnimating)
                    
                    Text("\(targetDNA.length) bp")
                        .font(.caption2)
                }
                
                // Vector DNA
                VStack {
                    Text("Vector DNA")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Circle()
                        .fill(Color.green)
                        .frame(width: 60, height: 60)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever().delay(0.5), value: isAnimating)
                    
                    Text("Plasmid")
                        .font(.caption2)
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct DNACuttingView: View {
    let targetDNA: DNAFragment
    let vectorDNA: DNAFragment
    
    @State private var isCut = false
    @State private var isAnimating = true
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 30) {
                // Target DNA cutting
                VStack {
                    Text("Target DNA")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 2) {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 35, height: 20)
                            .cornerRadius(5)
                        
                        if isCut {
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: 2, height: 20)
                        }
                        
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 35, height: 20)
                            .cornerRadius(5)
                    }
                    .animation(.easeInOut(duration: 1.0), value: isCut)
                    
                    Text("Cut into fragments")
                        .font(.caption2)
                }
                
                // Vector DNA cutting
                VStack {
                    Text("Vector DNA")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 60, height: 60)
                        
                        if isCut {
                            Path { path in
                                path.move(to: CGPoint(x: 30, y: 10))
                                path.addLine(to: CGPoint(x: 30, y: 50))
                            }
                            .stroke(Color.red, lineWidth: 3)
                            .animation(.easeInOut(duration: 1.0), value: isCut)
                        }
                    }
                    
                    Text("Linearized")
                        .font(.caption2)
                }
            }
            
            // Restriction enzyme
            HStack {
                Image(systemName: "scissors")
                    .foregroundColor(.red)
                    .font(.title)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(), value: isAnimating)
                
                Text("Restriction Enzyme")
                    .font(.caption)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isCut = true
            }
        }
    }
}

struct LigaseActionView: View {
    @State private var isJoined = false
    @State private var isAnimating = true
    
    var body: some View {
        VStack(spacing: 20) {
            // DNA fragments coming together
            HStack(spacing: 20) {
                // Fragment 1
                VStack {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 40, height: 20)
                        .cornerRadius(5)
                    
                    Text("Target")
                        .font(.caption2)
                }
                .offset(x: isJoined ? -10 : 0)
                .animation(.easeInOut(duration: 2.0), value: isJoined)
                
                // Ligase
                Image(systemName: "link")
                    .foregroundColor(.purple)
                    .font(.title)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(), value: isAnimating)
                
                // Vector
                VStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 40, height: 40)
                    
                    Text("Vector")
                        .font(.caption2)
                }
                .offset(x: isJoined ? 10 : 0)
                .animation(.easeInOut(duration: 2.0), value: isJoined)
            }
            
            // Result
            if isJoined {
                VStack {
                    HStack(spacing: 5) {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 30, height: 15)
                            .cornerRadius(3)
                        
                        Circle()
                            .fill(Color.green)
                            .frame(width: 30, height: 30)
                        
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 30, height: 15)
                            .cornerRadius(3)
                    }
                    
                    Text("Recombinant DNA")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            if isAnimating {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isJoined = true
                }
            }
        }
        .onChange(of: isAnimating) { animating in
            if animating {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isJoined = true
                }
            }
        }
    }
}

struct TransformationView: View {
    @State private var showDNA = false
    @State private var dnaPosition: CGFloat = 0
    @State private var isAnimating = true
    
    var body: some View {
        VStack(spacing: 20) {
            // Host cell
            Circle()
                .fill(Color.green.opacity(0.3))
                .frame(width: 120, height: 120)
                .overlay(
                    Circle()
                        .stroke(Color.green, lineWidth: 2)
                )
                .overlay(
                    Text("E. coli")
                        .font(.caption)
                        .foregroundColor(.green)
                )
            
            // DNA entering
            if showDNA {
                Image(systemName: "circle.hexagongrid.fill")
                    .foregroundColor(.blue)
                    .font(.title)
                    .offset(y: dnaPosition)
                    .animation(.easeInOut(duration: 2.0), value: dnaPosition)
            }
            
            Text("Transformation in progress...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onAppear {
            if isAnimating {
                startTransformation()
            }
        }
        .onChange(of: isAnimating) { animating in
            if animating {
                startTransformation()
            }
        }
    }
    
    private func startTransformation() {
        showDNA = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dnaPosition = -60 // Move DNA into the cell
        }
    }
}

struct SelectionView: View {
    @State private var showResults = false
    @State private var isAnimating = true
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 40) {
                // Successful transformants
                VStack {
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                                .font(.title)
                        )
                    
                    Text("Successful")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("With recombinant DNA")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                }
                
                // Failed transformants
                VStack {
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "xmark")
                                .foregroundColor(.red)
                                .font(.title)
                        )
                    
                    Text("Failed")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Text("No recombinant DNA")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                }
            }
            
            Text("Antibiotic selection")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onAppear {
            if isAnimating {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showResults = true
                }
            }
        }
    }
}

// MARK: - 3D View

struct Cloning3DView: View {
    let targetDNA: DNAFragment
    let vectorDNA: DNAFragment
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("3D Cloning Visualization")
                    .font(.title2)
                    .padding()
                
                // Placeholder for 3D scene
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        VStack {
                            Image(systemName: "cube.box")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                            Text("3D Scene View")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
                    .frame(height: 300)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("3D Cloning")
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
    CloningVisualizationView(
        targetDNA: DNAFragment(sequence: "ATCGATCG", start: 0, end: 8),
        vectorDNA: DNAFragment(sequence: "GCTAGCTA", start: 0, end: 8)
    )
}
