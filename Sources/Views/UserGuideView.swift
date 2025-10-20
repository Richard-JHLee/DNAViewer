//
//  UserGuideView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-20.
//

import SwiftUI

struct UserGuideView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("User Guide")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Learn how to use DNA Viewer")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)
                    
                    // Getting Started
                    GuideSection(
                        title: "Getting Started",
                        icon: "play.circle.fill",
                        color: .green
                    ) {
                        GuideStep(
                            number: 1,
                            title: "View Default Sequence",
                            description: "The app loads a default DNA sequence (BRCA1) on startup. Explore the 3D structure by dragging to rotate and pinching to zoom."
                        )
                        
                        GuideStep(
                            number: 2,
                            title: "Navigate Groups",
                            description: "DNA sequences are divided into groups of 100 base pairs. Tap group buttons (G1, G2, G3...) to view different sections."
                        )
                        
                        GuideStep(
                            number: 3,
                            title: "Read Sequence",
                            description: "Tap the 'Sequence' button to show the sequence bar at the bottom, displaying nucleotide bases (A, T, G, C)."
                        )
                    }
                    
                    // Gene Library
                    GuideSection(
                        title: "Gene Library",
                        icon: "books.vertical.fill",
                        color: .purple
                    ) {
                        GuideStep(
                            number: 1,
                            title: "Open Gene Library",
                            description: "Tap the menu button (☰) → Gene Library to browse genes from NCBI database."
                        )
                        
                        GuideStep(
                            number: 2,
                            title: "Browse by Category",
                            description: "Choose from categories: Organism, Gene Type, Chromosome, Status, or Gene Family."
                        )
                        
                        GuideStep(
                            number: 3,
                            title: "Apply Gene",
                            description: "Select a gene and tap 'Apply' to load its DNA sequence and view in 3D."
                        )
                    }
                    
                    // Analysis Tools
                    GuideSection(
                        title: "Analysis Tools",
                        icon: "chart.bar.fill",
                        color: .blue
                    ) {
                        GuideStep(
                            number: 1,
                            title: "Open Analysis",
                            description: "Tap Analysis button to view GC content, base composition, and sequence statistics."
                        )
                        
                        GuideStep(
                            number: 2,
                            title: "GC Content",
                            description: "View the percentage of Guanine (G) and Cytosine (C) bases in your sequence."
                        )
                        
                        GuideStep(
                            number: 3,
                            title: "CpG Islands",
                            description: "Detect CpG islands - regions with high CG dinucleotide frequency."
                        )
                    }
                    
                    // Restriction Enzymes
                    GuideSection(
                        title: "Restriction Enzymes",
                        icon: "scissors.badge.ellipsis",
                        color: .orange
                    ) {
                        GuideStep(
                            number: 1,
                            title: "Select Enzymes",
                            description: "Tap Scissor button to view available restriction enzymes for your sequence."
                        )
                        
                        GuideStep(
                            number: 2,
                            title: "Choose Enzymes",
                            description: "Select one or more enzymes from the list. Available enzymes show the number of cut sites."
                        )
                        
                        GuideStep(
                            number: 3,
                            title: "Show in 3D",
                            description: "Tap 'Show 3D' to visualize cut sites in the 3D structure. Red markers indicate cutting positions."
                        )
                        
                        GuideStep(
                            number: 4,
                            title: "Virtual Digestion",
                            description: "Tap 'Digest' to simulate DNA cutting and view resulting fragments."
                        )
                    }
                    
                    // Tips & Tricks
                    GuideSection(
                        title: "Tips & Tricks",
                        icon: "lightbulb.fill",
                        color: .yellow
                    ) {
                        TipItem(
                            icon: "hand.draw",
                            title: "Rotation",
                            description: "Drag anywhere on the 3D view to rotate the DNA structure."
                        )
                        
                        TipItem(
                            icon: "arrow.up.left.and.arrow.down.right",
                            title: "Zoom",
                            description: "Pinch to zoom in/out on the 3D structure."
                        )
                        
                        TipItem(
                            icon: "eye.fill",
                            title: "Styles",
                            description: "Tap the eye icon to access different visualization styles and color schemes."
                        )
                        
                        TipItem(
                            icon: "arrow.counterclockwise.circle.fill",
                            title: "Reset View",
                            description: "Tap Reload to reset the camera and view to default position."
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("User Guide")
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

// MARK: - Guide Section

struct GuideSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            // Content
            content()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Guide Step

struct GuideStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Number badge
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Tip Item

struct TipItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.yellow)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    UserGuideView()
}

