//
//  HelpView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-20.
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    private var filteredFAQs: [FAQItem] {
        if searchText.isEmpty {
            return faqItems
        } else {
            return faqItems.filter { item in
                item.question.localizedCaseInsensitiveContains(searchText) ||
                item.answer.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Help & FAQ")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Frequently Asked Questions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.teal.opacity(0.1))
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search help topics...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // FAQ List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredFAQs) { faq in
                            FAQItemView(item: faq)
                        }
                    }
                    .padding()
                }
                
                // Contact Section
                VStack(spacing: 12) {
                    Divider()
                    
                    VStack(spacing: 8) {
                        Text("Still need help?")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Contact us for additional support")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            // TODO: Open email or support form
                        }) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("Contact Support")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.teal)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
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

// MARK: - FAQ Item View

struct FAQItemView: View {
    let item: FAQItem
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: item.icon)
                        .font(.title3)
                        .foregroundColor(item.color)
                        .frame(width: 30)
                    
                    Text(item.question)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(item.answer)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 42)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - FAQ Data Model

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    let icon: String
    let color: Color
}

private let faqItems: [FAQItem] = [
    FAQItem(
        question: "How do I load a different gene?",
        answer: "Open the sidebar menu (☰), tap 'Gene Library', select a category (e.g., Organism), choose a sub-category (e.g., Homo sapiens), then select a gene and tap 'Apply'.",
        icon: "books.vertical.fill",
        color: .purple
    ),
    FAQItem(
        question: "What do the groups (G1, G2, G3) mean?",
        answer: "DNA sequences are divided into groups of 100 base pairs each for better visualization. Group 1 shows bases 0-99, Group 2 shows 100-199, and so on. Tap any group button to view that section.",
        icon: "number.circle.fill",
        color: .blue
    ),
    FAQItem(
        question: "How do I use restriction enzymes?",
        answer: "Tap the Scissor button in the bottom menu. Select restriction enzymes from the list. Available enzymes show the number of cut sites. Tap 'Show 3D' to visualize cut positions in 3D, or 'Digest' to simulate DNA cutting.",
        icon: "scissors",
        color: .orange
    ),
    FAQItem(
        question: "What is GC Content analysis?",
        answer: "GC Content shows the percentage of Guanine (G) and Cytosine (C) bases in your DNA sequence. Higher GC content indicates more stable DNA regions. Access this feature from the Analysis Tools menu.",
        icon: "chart.bar.fill",
        color: .blue
    ),
    FAQItem(
        question: "How do I change the 3D visualization style?",
        answer: "Tap the eye icon (👁) in the top right corner to access Style & Color controls. You can switch between Double Helix, Ladder, and Ball & Stick representations, and customize base colors.",
        icon: "eye.fill",
        color: .indigo
    ),
    FAQItem(
        question: "Can I view the entire sequence at once?",
        answer: "For performance reasons, only 100 base pairs (or fewer for large sequences) are displayed at a time. Use the group navigation buttons to view different sections of the sequence.",
        icon: "speedometer",
        color: .green
    ),
    FAQItem(
        question: "What does the Rotation button do?",
        answer: "The Rotation button automatically rotates the DNA structure 360 degrees, allowing you to view it from all angles without manual dragging.",
        icon: "arrow.clockwise",
        color: .teal
    ),
    FAQItem(
        question: "How do I reset the view?",
        answer: "Tap the Reload button (⟲) in the bottom menu to reset the camera position, zoom level, and all highlights to their default state.",
        icon: "arrow.counterclockwise.circle.fill",
        color: .gray
    ),
    FAQItem(
        question: "What are CpG Islands?",
        answer: "CpG islands are regions with high frequency of CG dinucleotides. They're important in gene regulation and often found near gene promoters. The Analysis Tools can detect these regions in your sequence.",
        icon: "waveform.path",
        color: .pink
    ),
    FAQItem(
        question: "Can I export or share sequences?",
        answer: "Currently, the app focuses on visualization and analysis. Export features may be added in future updates based on user feedback.",
        icon: "square.and.arrow.up",
        color: .green
    ),
    FAQItem(
        question: "Where does the gene data come from?",
        answer: "Gene data is fetched in real-time from NCBI (National Center for Biotechnology Information) using their E-utilities API. This ensures you always have access to the latest genetic information.",
        icon: "globe",
        color: .blue
    ),
    FAQItem(
        question: "Why are some genes not available?",
        answer: "Some genes may not have nucleotide sequences available in the NCBI database, or the sequence might be too large for mobile visualization. The app works best with sequences under 10,000 base pairs.",
        icon: "exclamationmark.triangle.fill",
        color: .orange
    )
]

#Preview {
    HelpView()
}

