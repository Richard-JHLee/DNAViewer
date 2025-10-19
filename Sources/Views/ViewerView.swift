//
//  ViewerView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import SwiftUI
import SceneKit

struct ViewerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var sceneManager = DNASceneManager()
    
    let sequence: DNASequence
    @ObservedObject var viewModel: DNAViewModel
    
    @State private var showInfo = false
    @State private var showLibrary = false
    @State private var showTranslation = false
    @State private var showMutation = false
    @State private var showSequenceBar = true
    @State private var showAnalysis = false
    @State private var showStyleAndColor = false
    @State private var showSidebar = false
    @State private var showSettings = false
    @State private var showRestrictionEnzyme = false
    @State private var showVirtualCloning = false
    
    // Digest and Educational Features
    @State private var showDigestionResult = false
    @State private var showGelElectrophoresis = false
    @State private var showCloningProcess = false
    @State private var showTransformation = false
    @State private var showVerification = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar (full width, below status bar)
            DNAViewerTopBar(
                sequenceName: extractFullName(from: sequence.name),
                sequenceId: extractGeneId(from: sequence.name),
                onDismiss: { 
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSidebar = true
                    }
                },
                onLibrary: { showLibrary = true },
                onToggleControls: {
                    withAnimation {
                        showStyleAndColor.toggle()
                    }
                },
                showStyleAndColor: showStyleAndColor
            )
            
            // Main content area with 3D Scene and bottom controls
            VStack(spacing: 0) {
                // 3D Scene View (fills available space above sequence info)
                ZStack {
                    SceneView(
                        scene: sceneManager.scene,
                        pointOfView: nil,
                        options: [.autoenablesDefaultLighting]
                    )
                    .background(Color(red: 0.03, green: 0.08, blue: 0.15)) // Dark navy background
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                sceneManager.handleDrag(translation: value.translation)
                            }
                    )
                    .simultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                sceneManager.handleZoom(scale: value)
                            }
                    )
                    
                    // Floating Digest button - only show when cut sites are highlighted
                    if !sceneManager.highlightedCutSites.isEmpty {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                
                                Button(action: { showDigestionResult = true }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "scissors.badge.ellipsis")
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("Digest")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                        
                                        // Badge showing cut site count
                                        Text("\(sceneManager.highlightedCutSites.count) sites")
                                            .font(.system(size: 10))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.orange, Color.red]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        .opacity(0.95) // 약간 투명하게 하여 뒤의 3D가 살짝 보이도록
                                    )
                                    .cornerRadius(16)
                                    .shadow(color: .orange.opacity(0.5), radius: 12, x: 0, y: 4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                                .padding(.trailing, 16)
                                .padding(.bottom, 16)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: sceneManager.highlightedCutSites.count)
                        .allowsHitTesting(true) // 버튼만 터치 가능, 나머지는 3D view로 전달
                    }
                    
                }  // End ZStack (Scene)
                .frame(maxWidth: .infinity, maxHeight: .infinity) // 가능한 모든 공간 사용
                
                // Sequence Bar (full width, at bottom)
                if showSequenceBar {
                    SequenceBar(
                        sequence: sequence.sequence,
                        selectedRange: $sceneManager.selectedRange,
                        sceneManager: sceneManager
                    )
                    .frame(height: 120)
                }
                
                // Bottom Menu
                HStack(spacing: 0) {
                    // Sequence button
                    BottomMenuButton(
                        icon: "textformat.abc",
                        title: "Sequence",
                        action: { showSequenceBar.toggle() }
                    )
                    
                    // Rotation button
                    BottomMenuButton(
                        icon: "arrow.clockwise",
                        title: "Rotation",
                        action: { sceneManager.animateRotation() }
                    )
                    
                    // Scissor button
                    BottomMenuButton(
                        icon: "scissors",
                        title: "Scissor",
                        action: { showRestrictionEnzyme = true }
                    )
                    
                    // Cloning button
                    BottomMenuButton(
                        icon: "arrow.triangle.branch",
                        title: "Cloning",
                        action: { showVirtualCloning = true }
                    )
                    
                    // Analysis button
                    BottomMenuButton(
                        icon: "chart.bar.fill",
                        title: "Analysis",
                        action: { showAnalysis = true }
                    )
                    
                    // Reload button
                    BottomMenuButton(
                        icon: "arrow.counterclockwise.circle.fill",
                        title: "Reload",
                        action: { sceneManager.resetView() }
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .padding(.bottom, 0)
            }  // End VStack (Main content)
        }  // End VStack (Top Bar + Main content)
        .onChange(of: sceneManager.colorSettings.adenineColor) { _ in
            sceneManager.rebuildScene()
        }
        .onChange(of: sceneManager.colorSettings.thymineColor) { _ in
            sceneManager.rebuildScene()
        }
        .onChange(of: sceneManager.colorSettings.guanineColor) { _ in
            sceneManager.rebuildScene()
        }
        .onChange(of: sceneManager.colorSettings.cytosineColor) { _ in
            sceneManager.rebuildScene()
        }
        .onChange(of: sceneManager.colorSettings.hydrogenBondColor) { _ in
            sceneManager.rebuildScene()
        }
        .sheet(isPresented: $showInfo) {
            InfoSheet(sequence: sequence)
        }
        .sheet(isPresented: $showLibrary) {
            LibraryView(viewModel: viewModel)
        }
        .sheet(isPresented: $showTranslation) {
            TranslationSheet(sequence: sequence)
        }
        .sheet(isPresented: $showMutation) {
            MutationSheet(sequence: sequence)
        }
        .sheet(isPresented: $showAnalysis) {
            AnalysisSheet(sequence: sequence)
        }
        .sheet(isPresented: $showRestrictionEnzyme) {
            RestrictionEnzymeView(sequence: sequence, sceneManager: sceneManager)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showVirtualCloning) {
            VirtualCloningView(sequence: sequence)
        }
        .sheet(isPresented: $showDigestionResult) {
            let dummyFragments = [
                DNAFragment(sequence: "ATGGATTTATCTGCT", start: 0, end: 15),
                DNAFragment(sequence: "GCTAGCTAGCTAGCTA", start: 15, end: 31)
            ]
            DigestionResultView(fragments: dummyFragments, enzymes: [])
        }
        .sheet(isPresented: $showGelElectrophoresis) {
            let dummyFragments = [
                DNAFragment(sequence: "ATGGATTTATCTGCT", start: 0, end: 15),
                DNAFragment(sequence: "GCTAGCTAGCTAGCTA", start: 15, end: 31)
            ]
            if #available(iOS 16.0, *) {
                GelElectrophoresisView(fragments: dummyFragments, enzymes: [])
                    .presentationDetents([.medium, .large])
            } else {
                GelElectrophoresisView(fragments: dummyFragments, enzymes: [])
            }
        }
        .sheet(isPresented: $showCloningProcess) {
            let targetDNA = DNAFragment(sequence: "ATGGATTTATCTGCT", start: 0, end: 15)
            let vectorDNA = DNAFragment(sequence: "GCTAGCTAGCTAGCTA", start: 0, end: 16)
            if #available(iOS 16.0, *) {
                CloningVisualizationView(targetDNA: targetDNA, vectorDNA: vectorDNA)
                    .presentationDetents([.medium, .large])
            } else {
                CloningVisualizationView(targetDNA: targetDNA, vectorDNA: vectorDNA)
            }
        }
        .sheet(isPresented: $showTransformation) {
            if #available(iOS 16.0, *) {
                TransformationAnimationView()
                    .presentationDetents([.medium, .large])
            } else {
                TransformationAnimationView()
            }
        }
        .sheet(isPresented: $showVerification) {
            if #available(iOS 16.0, *) {
                VerificationGuideView()
                    .presentationDetents([.medium, .large])
            } else {
                VerificationGuideView()
            }
        }
        .overlay(
            // Sidebar Menu
            Group {
                if showSidebar {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showSidebar = false
                            }
                        }
                    
                    HStack {
                        SidebarMenu(
                            isPresented: $showSidebar,
                            onLibrary: { showLibrary = true },
                            onAnalysis: { showAnalysis = true },
                            onRestrictionEnzymes: { showRestrictionEnzyme = true },
                            onSettings: { 
                                showSettings = true
                            },
                            onAbout: { 
                                // TODO: About sheet
                            }
                        )
                        .frame(width: 280)
                        .transition(.move(edge: .leading))
                        
                        Spacer()
                    }
                }
            }
        )
        .overlay(
            // Control Bar overlay (floating at bottom)
            Group {
                if showStyleAndColor {
                    VStack {
                        Spacer()
                        ControlBar(sceneManager: sceneManager, showStyleAndColor: $showStyleAndColor)
                            .background(.ultraThinMaterial)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        )
        .onAppear {
            // 화면이 나타날 때 시퀀스 로드
            print("🎬 ViewerView.onAppear: \(sequence.name)")
            sceneManager.loadSequence(sequence)
        }
        .onChange(of: sequence.id) { newId in
            // 시퀀스가 변경되면 새로운 시퀀스 로드
            print("🔄 ViewerView.onChange(sequence.id): \(sequence.name) (id: \(newId))")
            sceneManager.loadSequence(sequence)
        }
    }
    
    // Extract gene ID from name (e.g., "BRCA1 - Breast Cancer 1" -> "BRCA1")
    private func extractGeneId(from name: String) -> String {
        if let dashIndex = name.firstIndex(of: "-") {
            return String(name[..<dashIndex]).trimmingCharacters(in: .whitespaces)
        }
        return name
    }
    
    // Extract full name from sequence name (e.g., "BRCA1 - Breast Cancer 1" -> "Breast Cancer 1")
    private func extractFullName(from name: String) -> String {
        if let dashIndex = name.firstIndex(of: "-") {
            let afterDash = name.index(after: dashIndex)
            if afterDash < name.endIndex {
                return String(name[afterDash...]).trimmingCharacters(in: .whitespaces)
            }
        }
        return name
    }
}

// MARK: - DNA Viewer Top Bar
struct DNAViewerTopBar: View {
    let sequenceName: String
    let sequenceId: String
    let onDismiss: () -> Void
    let onLibrary: () -> Void
    let onToggleControls: () -> Void
    let showStyleAndColor: Bool
    
    var body: some View {
        HStack {
            // Hamburger Menu / Back button
            Button(action: onDismiss) {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            .accessibilityLabel("Back")
            
            Spacer()
            
            // Sequence Name
            Text(sequenceName)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
            
            Spacer()
            
            // Right buttons
            HStack(spacing: 12) {
                // Library/Info button
                Button(action: onLibrary) {
                    Image(systemName: "books.vertical.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .accessibilityLabel("Library")
                
                // Eye icon (toggle controls)
                Button(action: onToggleControls) {
                    Image(systemName: showStyleAndColor ? "eye.slash.fill" : "eye.fill")
                        .font(.title2)
                        .foregroundColor(showStyleAndColor ? .blue : .primary)
                }
                .accessibilityLabel("Toggle Controls")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        #if os(macOS)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.95))
        #else
        .background(.ultraThinMaterial)
        #endif
    }
    
}

struct BottomMenuButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Scale button style for floating digest button
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    ViewerView(sequence: DNASequence(
        name: "Sample Gene",
        sequence: "ATGCGATCGATCGATCGATCGATCG",
        summary: "A sample DNA sequence"
    ), viewModel: DNAViewModel())
}

