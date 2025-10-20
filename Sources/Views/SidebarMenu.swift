//
//  SidebarMenu.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-18.
//

import SwiftUI

struct SidebarMenu: View {
    @Binding var isPresented: Bool
    let onLibrary: () -> Void
    let onAnalysis: () -> Void
    let onRestrictionEnzymes: () -> Void
    let onSettings: () -> Void
    let onAbout: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // DNAViewer 로고 이미지
                    Image("DNAViewerLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DNA Viewer")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Genetic Explorer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Divider()
                    .padding(.vertical, 16)
            }
            
            // Menu Items
            VStack(alignment: .leading, spacing: 0) {
                MenuItem(
                    icon: "books.vertical.fill",
                    title: "Sample Genes Library",
                    subtitle: "Explore 10 important human genes",
                    color: .purple
                ) {
                    isPresented = false
                    onLibrary()
                }
                
                MenuItem(
                    icon: "chart.bar.fill",
                    title: "Analysis Tools",
                    subtitle: "GC Content, CpG Islands, Restriction Sites",
                    color: .blue
                ) {
                    isPresented = false
                    onAnalysis()
                }
                
                MenuItem(
                    icon: "scissors.badge.ellipsis",
                    title: "Restriction Enzymes",
                    subtitle: "Cut DNA & Educational Features",
                    color: .orange
                ) {
                    isPresented = false
                    onRestrictionEnzymes()
                }
                
                MenuItem(
                    icon: "gear",
                    title: "Settings",
                    subtitle: "App preferences and configuration",
                    color: .gray
                ) {
                    isPresented = false
                    onSettings()
                }
                
                MenuItem(
                    icon: "info.circle.fill",
                    title: "About",
                    subtitle: "Version 1.0.0 • Learn more",
                    color: .green
                ) {
                    isPresented = false
                    onAbout()
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Footer
            VStack(spacing: 8) {
                Divider()
                
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text("Made with ❤️ for Science")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        #if os(macOS)
        .background(Color(NSColor.windowBackgroundColor))
        #else
        .background(Color(.systemBackground))
        #endif
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

struct MenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SidebarMenu(
        isPresented: .constant(true),
        onLibrary: {},
        onAnalysis: {},
        onRestrictionEnzymes: {},
        onSettings: {},
        onAbout: {}
    )
}
