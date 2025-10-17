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
    
    @State private var showInfo = false
    @State private var showTranslation = false
    @State private var showMutation = false
    @State private var showSequenceBar = true
    @State private var showAnalysis = false
    @State private var showStyleAndColor = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar (full width, below status bar)
            DNAViewerTopBar(
                sequenceName: extractFullName(from: sequence.name),
                sequenceId: extractGeneId(from: sequence.name),
                onDismiss: { dismiss() },
                onLibrary: { showInfo = true },
                onToggleControls: {
                    withAnimation {
                        showStyleAndColor.toggle()
                    }
                },
                showStyleAndColor: showStyleAndColor
            )
            
            // 3D Scene View (fills remaining space)
            ZStack {
                SceneView(
                    scene: sceneManager.scene,
                    pointOfView: nil,
                    options: [.allowsCameraControl, .autoenablesDefaultLighting]
                )
                .background(Color(red: 0.03, green: 0.08, blue: 0.15)) // Dark navy background
                
                // Overlay UI on Scene
                VStack(spacing: 0) {
                    // Side Controls (floating on right, top area)
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 16) {
                            Button(action: { sceneManager.animateRotation() }) {
                                Image(systemName: sceneManager.isAnimating ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                            }
                            
                            Button(action: { showAnalysis = true }) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                            }
                            
                            Button(action: { sceneManager.resetView() }) {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                
                // Bottom section - Control Bar and Sequence Bar
                VStack(spacing: 0) {
                    // Control Bar (full width, above Sequence Bar)
                    if showStyleAndColor {
                        ControlBar(sceneManager: sceneManager, showStyleAndColor: $showStyleAndColor)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    // Sequence Bar (full width, at bottom)
                    if showSequenceBar {
                        SequenceBar(
                            sequence: sequence.sequence,
                            selectedRange: $sceneManager.selectedRange,
                            sceneManager: sceneManager
                        )
                        .frame(height: 120)
                    }
                }  // End VStack (Bottom section)
            }  // End VStack (Scene overlay)
            }  // End ZStack (Scene)
        }  // End VStack (Top Bar + Scene)
        .onAppear {
            sceneManager.loadSequence(sequence)
        }
        .sheet(isPresented: $showInfo) {
            InfoSheet(sequence: sequence)
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
            
            // Sequence ID and Name
            VStack(spacing: 2) {
                Text(sequenceId)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(sequenceName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
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

#Preview {
    ViewerView(sequence: DNASequence(
        name: "Sample Gene",
        sequence: "ATGCGATCGATCGATCGATCGATCG",
        summary: "A sample DNA sequence"
    ))
}

