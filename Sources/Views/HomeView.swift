//
//  HomeView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = DNAViewModel()
    @State private var showSearchSheet = false
    @State private var showLibrary = false
    @State private var selectedSequence: DNASequence?
    @State private var recentItems: [RecentItem] = []
    @State private var showViewer = false
    
    var body: some View {
        if showViewer, let sequence = selectedSequence {
            ViewerView(sequence: sequence, viewModel: viewModel)
        } else {
            NavigationView {
                VStack(spacing: 0) {
                    // Top Bar (ProteinApp style)
                    DNAHomeTopBar()
                    
                    // Main Content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            VStack(spacing: 8) {
                                Image(systemName: "dna")
                                    .font(.system(size: 60))
                                    .foregroundColor(.blue)
                                
                                Text("DNA Viewer")
                                    .font(.system(size: 36, weight: .bold))
                                
                                Text("Explore DNA sequences and genetic information")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 20)
                        
                            // Main Actions
                            VStack(spacing: 16) {
                                ActionCard(
                                    icon: "books.vertical.fill",
                                    title: "Sample Genes Library",
                                    description: "Explore 10 important human genes",
                                    color: .purple
                                ) {
                                    showLibrary = true
                                }
                                
                                ActionCard(
                                    icon: "magnifyingglass",
                                    title: "Load New Sequence",
                                    description: "Search by accession or PDB ID",
                                    color: .blue
                                ) {
                                    showSearchSheet = true
                                }
                                
                                ActionCard(
                                    icon: "graduationcap.fill",
                                    title: "Learning Mode",
                                    description: "Take quizzes and learn about DNA",
                                    color: .green
                                ) {
                                    // Navigate to learning mode
                                }
                            }
                            .padding(.horizontal)
                            
                            // Recent Items
                            if !recentItems.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Recently Viewed")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(recentItems) { item in
                                                RecentItemCard(item: item) {
                                                    // Load sequence
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            
                            Spacer(minLength: 40)
                        }
                    }
                }
                #if !os(macOS)
                .navigationBarHidden(true)
                #endif
                .sheet(isPresented: $showSearchSheet) {
                    SearchSheet()
                }
                .sheet(isPresented: $showLibrary) {
                    LibraryView(viewModel: viewModel)
                }
                .onAppear {
                    loadRecentItems()
                }
            }
        }
    }
    
    private func loadRecentItems() {
        recentItems = CacheManager.shared.loadRecentItems()
    }
}

// MARK: - DNA Home Top Bar (ProteinApp style)
struct DNAHomeTopBar: View {
    var body: some View {
        HStack {
            // App Logo/Icon
            Image(systemName: "dna")
                .font(.title2)
                .foregroundColor(.primary)
            
            Spacer()
            
            // App Title
            VStack(spacing: 2) {
                Text("DNA Viewer")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Genetic Explorer")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Settings/Info button (for symmetry)
            Button(action: {
                // Open settings or info
            }) {
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        #if os(macOS)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.95))
        #else
        .background(.ultraThinMaterial)
        #endif
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

struct ActionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(color)
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            #if os(macOS)
            .background(Color(NSColor.controlBackgroundColor))
            #else
            .background(Color(.systemBackground))
            #endif
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecentItemCard: View {
    let item: RecentItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "dna")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(item.type)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 140)
            .padding()
            #if os(macOS)
            .background(Color(NSColor.controlBackgroundColor))
            #else
            .background(Color(.systemBackground))
            #endif
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HomeView()
}