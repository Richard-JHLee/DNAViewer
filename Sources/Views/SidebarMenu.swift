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
                        title: LanguageHelper.string("menu_about"),
                        subtitle: LanguageHelper.string("menu_about_subtitle"),
                        color: .indigo
                    ) {
                        isPresented = false
                        onAbout()
                    }
                    
                    MenuItem(
                        icon: "book.fill",
                        title: LanguageHelper.string("menu_user_guide"),
                        subtitle: LanguageHelper.string("menu_user_guide_subtitle"),
                        color: .green
                    ) {
                        isPresented = false
                        onUserGuide()
                    }
                    
                    MenuItem(
                        icon: "star.fill",
                        title: LanguageHelper.string("menu_features"),
                        subtitle: LanguageHelper.string("menu_features_subtitle"),
                        color: .yellow
                    ) {
                        isPresented = false
                        onFeatures()
                    }
                    
                    MenuItem(
                        icon: "questionmark.circle.fill",
                        title: LanguageHelper.string("menu_help"),
                        subtitle: LanguageHelper.string("menu_help_subtitle"),
                        color: .teal
                    ) {
                        isPresented = false
                        onHelp()
                    }
                    
                    MenuItem(
                        icon: "gear",
                        title: LanguageHelper.string("menu_settings"),
                        subtitle: LanguageHelper.string("menu_settings_subtitle"),
                        color: .gray
                    ) {
                        isPresented = false
                        onSettings()
                    }
                    
                    MenuItem(
                        icon: "hand.raised.fill",
                        title: LanguageHelper.string("menu_privacy"),
                        subtitle: LanguageHelper.string("menu_privacy_subtitle"),
                        color: .brown
                    ) {
                        isPresented = false
                        onPrivacy()
                    }
                    
                    MenuItem(
                        icon: "doc.text.fill",
                        title: LanguageHelper.string("menu_terms"),
                        subtitle: LanguageHelper.string("menu_terms_subtitle"),
                        color: .cyan
                    ) {
                        isPresented = false
                        onTerms()
                    }
                    
                    MenuItem(
                        icon: "doc.plaintext.fill",
                        title: LanguageHelper.string("menu_license"),
                        subtitle: LanguageHelper.string("menu_license_subtitle"),
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
