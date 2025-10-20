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
    let onUserGuide: () -> Void
    let onFeatures: () -> Void
    let onHelp: () -> Void
    let onSettings: () -> Void
    let onAbout: () -> Void
    let onPrivacy: () -> Void
    let onTerms: () -> Void
    let onLicense: () -> Void
    
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
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    MenuItem(
                        icon: "info.circle.fill",
                        title: "About",
                        subtitle: "App information and version",
                        color: .indigo
                    ) {
                        isPresented = false
                        onAbout()
                    }
                    
                    MenuItem(
                        icon: "book.fill",
                        title: "User Guide",
                        subtitle: "Learn how to use DNA Viewer",
                        color: .green
                    ) {
                        isPresented = false
                        onUserGuide()
                    }
                    
                    MenuItem(
                        icon: "star.fill",
                        title: "Features",
                        subtitle: "Key features and capabilities",
                        color: .yellow
                    ) {
                        isPresented = false
                        onFeatures()
                    }
                    
                    MenuItem(
                        icon: "questionmark.circle.fill",
                        title: "Help & FAQ",
                        subtitle: "Common questions and troubleshooting",
                        color: .teal
                    ) {
                        isPresented = false
                        onHelp()
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
                        icon: "hand.raised.fill",
                        title: "Privacy Policy",
                        subtitle: "Data protection and privacy",
                        color: .brown
                    ) {
                        isPresented = false
                        onPrivacy()
                    }
                    
                    MenuItem(
                        icon: "doc.text.fill",
                        title: "Terms of Service",
                        subtitle: "Usage terms and conditions",
                        color: .cyan
                    ) {
                        isPresented = false
                        onTerms()
                    }
                    
                    MenuItem(
                        icon: "doc.plaintext.fill",
                        title: "License",
                        subtitle: "MIT License and open source",
                        color: .mint
                    ) {
                        isPresented = false
                        onLicense()
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Footer - License Information
            VStack(spacing: 12) {
                Divider()
                    .padding(.horizontal, 20)
                
                VStack(spacing: 8) {
                    Text("© 2025 AVAS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("All rights reserved")
                        .font(.caption2)
                        .foregroundColor(.secondary)
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
        onUserGuide: {},
        onFeatures: {},
        onHelp: {},
        onSettings: {},
        onAbout: {},
        onPrivacy: {},
        onTerms: {},
        onLicense: {}
    )
}
