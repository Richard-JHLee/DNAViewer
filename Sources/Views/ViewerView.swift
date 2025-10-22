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
    @State private var showAbout = false
    @State private var showUserGuide = false
    @State private var showFeatures = false
    @State private var showHelp = false
    @State private var showPrivacy = false
    @State private var showTerms = false
    @State private var showLicense = false
    
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
                .padding(.horizontal, 2)
                .padding(.vertical, 3)  // Even smaller vertical padding
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
        .onChange(of: showSettings) { newValue in
            if !newValue {
                // Settings 화면이 닫히면 사이드바 다시 열기
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showSidebar = true
                }
            }
        }
        .sheet(isPresented: $showAbout) {
            AboutContentView()
        }
        .onChange(of: showAbout) { newValue in
            if !newValue {
                // About 화면이 닫히면 사이드바 다시 열기
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showSidebar = true
                }
            }
        }
        .sheet(isPresented: $showUserGuide) {
            UserGuideContentView()
        }
        .onChange(of: showUserGuide) { newValue in
            if !newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showSidebar = true
                }
            }
        }
        .sheet(isPresented: $showFeatures) {
            FeaturesContentView()
        }
        .onChange(of: showFeatures) { newValue in
            if !newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showSidebar = true
                }
            }
        }
        .sheet(isPresented: $showHelp) {
            HelpContentView()
        }
        .onChange(of: showHelp) { newValue in
            if !newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showSidebar = true
                }
            }
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyContentView()
        }
        .onChange(of: showPrivacy) { newValue in
            if !newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showSidebar = true
                }
            }
        }
        .sheet(isPresented: $showTerms) {
            TermsContentView()
        }
        .onChange(of: showTerms) { newValue in
            if !newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showSidebar = true
                }
            }
        }
        .sheet(isPresented: $showLicense) {
            LicenseContentView()
        }
        .onChange(of: showLicense) { newValue in
            if !newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showSidebar = true
                }
            }
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
                            onUserGuide: { showUserGuide = true },
                            onFeatures: { showFeatures = true },
                            onHelp: { showHelp = true },
                            onSettings: { showSettings = true },
                            onAbout: { showAbout = true },
                            onPrivacy: { showPrivacy = true },
                            onTerms: { showTerms = true },
                            onLicense: { showLicense = true }
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

// MARK: - About Content View

struct AboutContentView: View {
    @Environment(\.dismiss) var dismiss
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 앱 아이콘 및 이름
                    HStack(spacing: 16) {
                        Image("DNAViewerLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                            )
                            .shadow(color: .blue.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LanguageHelper.string("app_name"))
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Version \(appVersion) (Build \(buildNumber))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // 앱 설명
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LanguageHelper.string("about_title"))
                            .font(.headline)
                        
                        Text(LanguageHelper.string("about_description"))
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // 주요 기능
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LanguageHelper.string("about_key_features"))
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            AboutFeatureRow(
                                icon: "cube.fill",
                                title: LanguageHelper.string("about_feature_3d_title"),
                                description: LanguageHelper.string("about_feature_3d_desc")
                            )
                            AboutFeatureRow(
                                icon: "books.vertical.fill",
                                title: LanguageHelper.string("about_feature_ncbi_title"),
                                description: LanguageHelper.string("about_feature_ncbi_desc")
                            )
                            AboutFeatureRow(
                                icon: "chart.bar.fill",
                                title: LanguageHelper.string("about_feature_analysis_title"),
                                description: LanguageHelper.string("about_feature_analysis_desc")
                            )
                            AboutFeatureRow(
                                icon: "scissors",
                                title: LanguageHelper.string("about_feature_enzyme_title"),
                                description: LanguageHelper.string("about_feature_enzyme_desc")
                            )
                            AboutFeatureRow(
                                icon: "paintpalette.fill",
                                title: LanguageHelper.string("about_feature_color_title"),
                                description: LanguageHelper.string("about_feature_color_desc")
                            )
                            AboutFeatureRow(
                                icon: "hand.tap.fill",
                                title: LanguageHelper.string("about_feature_interact_title"),
                                description: LanguageHelper.string("about_feature_interact_desc")
                            )
                            AboutFeatureRow(
                                icon: "graduationcap.fill",
                                title: LanguageHelper.string("about_feature_edu_title"),
                                description: LanguageHelper.string("about_feature_edu_desc")
                            )
                        }
                    }
                    
                    Divider()
                    
                    // 개발자 정보
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LanguageHelper.string("about_developer"))
                            .font(.headline)
                        
                        Text("AVAS")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Text(LanguageHelper.string("about_copyright"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    
                    Divider()
                    
                    // 기술 정보
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LanguageHelper.string("about_tech_stack"))
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            TechStackRow(name: "SwiftUI", description: "Modern UI Framework")
                            TechStackRow(name: "SceneKit", description: "3D Graphics Rendering")
                            TechStackRow(name: "NCBI E-utilities", description: "Gene Database API")
                            TechStackRow(name: "Charts Framework", description: "Data Visualization")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(LanguageHelper.string("menu_about"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LanguageHelper.string("done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AboutFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
    }
}

struct TechStackRow: View {
    let name: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - User Guide Content View

struct UserGuideContentView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LanguageHelper.string("guide_subtitle"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)
                    
                    // 시작하기
                    GuideSection(title: LanguageHelper.string("guide_getting_started"), color: .green) {
                        GuideItem(title: LanguageHelper.string("guide_getting_started_1_title"), description: LanguageHelper.string("guide_getting_started_1_desc"))
                        GuideItem(title: LanguageHelper.string("guide_getting_started_2_title"), description: LanguageHelper.string("guide_getting_started_2_desc"))
                        GuideItem(title: LanguageHelper.string("guide_getting_started_3_title"), description: LanguageHelper.string("guide_getting_started_3_desc"))
                        GuideItem(title: LanguageHelper.string("guide_getting_started_4_title"), description: LanguageHelper.string("guide_getting_started_4_desc"))
                    }
                    
                    // 유전자 라이브러리
                    GuideSection(title: LanguageHelper.string("guide_gene_library"), color: .purple) {
                        GuideItem(title: LanguageHelper.string("guide_gene_library_1_title"), description: LanguageHelper.string("guide_gene_library_1_desc"))
                        GuideItem(title: LanguageHelper.string("guide_gene_library_2_title"), description: LanguageHelper.string("guide_gene_library_2_desc"))
                        GuideItem(title: LanguageHelper.string("guide_gene_library_3_title"), description: LanguageHelper.string("guide_gene_library_3_desc"))
                        GuideItem(title: LanguageHelper.string("guide_gene_library_4_title"), description: LanguageHelper.string("guide_gene_library_4_desc"))
                    }
                    
                    // 분석 도구
                    GuideSection(title: LanguageHelper.string("guide_analysis_tools"), color: .blue) {
                        GuideItem(title: LanguageHelper.string("guide_analysis_tools_1_title"), description: LanguageHelper.string("guide_analysis_tools_1_desc"))
                        GuideItem(title: LanguageHelper.string("guide_analysis_tools_2_title"), description: LanguageHelper.string("guide_analysis_tools_2_desc"))
                        GuideItem(title: LanguageHelper.string("guide_analysis_tools_3_title"), description: LanguageHelper.string("guide_analysis_tools_3_desc"))
                        GuideItem(title: LanguageHelper.string("guide_analysis_tools_4_title"), description: LanguageHelper.string("guide_analysis_tools_4_desc"))
                    }
                    
                    // 제한 효소
                    GuideSection(title: LanguageHelper.string("guide_restriction_enzymes"), color: .orange) {
                        GuideItem(title: LanguageHelper.string("guide_restriction_enzymes_1_title"), description: LanguageHelper.string("guide_restriction_enzymes_1_desc"))
                        GuideItem(title: LanguageHelper.string("guide_restriction_enzymes_2_title"), description: LanguageHelper.string("guide_restriction_enzymes_2_desc"))
                        GuideItem(title: LanguageHelper.string("guide_restriction_enzymes_3_title"), description: LanguageHelper.string("guide_restriction_enzymes_3_desc"))
                        GuideItem(title: LanguageHelper.string("guide_restriction_enzymes_4_title"), description: LanguageHelper.string("guide_restriction_enzymes_4_desc"))
                    }
                    
                    // 사용 팁
                    GuideSection(title: LanguageHelper.string("guide_usage_tips"), color: .yellow) {
                        GuideItem(title: LanguageHelper.string("guide_usage_tips_1_title"), description: LanguageHelper.string("guide_usage_tips_1_desc"))
                        GuideItem(title: LanguageHelper.string("guide_usage_tips_2_title"), description: LanguageHelper.string("guide_usage_tips_2_desc"))
                        GuideItem(title: LanguageHelper.string("guide_usage_tips_3_title"), description: LanguageHelper.string("guide_usage_tips_3_desc"))
                        GuideItem(title: LanguageHelper.string("guide_usage_tips_4_title"), description: LanguageHelper.string("guide_usage_tips_4_desc"))
                    }
                }
                .padding()
            }
            .navigationTitle(LanguageHelper.string("guide_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LanguageHelper.string("done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct GuideSection<Content: View>: View {
    let title: String
    let color: Color
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct GuideItem: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Help Content View

struct HelpContentView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // 일반 사용
                    HelpCategory(title: LanguageHelper.string("help_general_title"), icon: "questionmark.circle.fill", color: .blue) {
                        FAQSection(
                            question: LanguageHelper.string("help_general_1_q"),
                            answer: LanguageHelper.string("help_general_1_a")
                        )
                        
                        FAQSection(
                            question: LanguageHelper.string("help_general_2_q"),
                            answer: LanguageHelper.string("help_general_2_a")
                        )
                        
                        FAQSection(
                            question: LanguageHelper.string("help_general_3_q"),
                            answer: LanguageHelper.string("help_general_3_a")
                        )
                    }
                    
                    // 3D 시각화
                    HelpCategory(title: LanguageHelper.string("help_3d_viz_title"), icon: "cube.fill", color: .purple) {
                        FAQSection(
                            question: LanguageHelper.string("help_3d_1_q"),
                            answer: LanguageHelper.string("help_3d_1_a")
                        )
                        
                        FAQSection(
                            question: LanguageHelper.string("help_3d_2_q"),
                            answer: LanguageHelper.string("help_3d_2_a")
                        )
                        
                        FAQSection(
                            question: LanguageHelper.string("help_3d_3_q"),
                            answer: LanguageHelper.string("help_3d_3_a")
                        )
                        
                        FAQSection(
                            question: LanguageHelper.string("help_3d_4_q"),
                            answer: LanguageHelper.string("help_3d_4_a")
                        )
                    }
                    
                    // 분석 도구
                    HelpCategory(title: LanguageHelper.string("help_analysis_title"), icon: "chart.bar.fill", color: .green) {
                        FAQSection(
                            question: LanguageHelper.string("help_analysis_1_q"),
                            answer: LanguageHelper.string("help_analysis_1_a")
                        )
                        
                        FAQSection(
                            question: LanguageHelper.string("help_analysis_2_q"),
                            answer: LanguageHelper.string("help_analysis_2_a")
                        )
                        
                        FAQSection(
                            question: LanguageHelper.string("help_analysis_3_q"),
                            answer: LanguageHelper.string("help_analysis_3_a")
                        )
                        
                        FAQSection(
                            question: LanguageHelper.string("help_analysis_4_q"),
                            answer: LanguageHelper.string("help_analysis_4_a")
                        )
                    }
                    
                    // 제한 효소
                    HelpCategory(title: LanguageHelper.string("help_enzyme_title"), icon: "scissors", color: .orange) {
                        FAQSection(
                            question: LanguageHelper.string("help_enzyme_1_q"),
                            answer: LanguageHelper.string("help_enzyme_1_a")
                        )
                        
                        FAQSection(
                            question: LanguageHelper.string("help_enzyme_2_q"),
                            answer: LanguageHelper.string("help_enzyme_2_a")
                        )
                        
                        FAQSection(
                            question: LanguageHelper.string("help_enzyme_3_q"),
                            answer: LanguageHelper.string("help_enzyme_3_a")
                        )
                        
                        FAQSection(
                            question: LanguageHelper.string("help_enzyme_4_q"),
                            answer: LanguageHelper.string("help_enzyme_4_a")
                        )
                    }
                    
                    // 성능 및 문제 해결
                    HelpCategory(title: LanguageHelper.string("help_troubleshooting_title"), icon: "wrench.and.screwdriver.fill", color: .red) {
                        FAQSection(
                            question: LanguageHelper.string("help_troubleshooting_1_q"),
                            answer: LanguageHelper.string("help_troubleshooting_1_a")
                        )
                        
                        FAQSection(
                            question: LanguageHelper.string("help_troubleshooting_2_q"),
                            answer: LanguageHelper.string("help_troubleshooting_2_a")
                        )
                        
                        FAQSection(
                            question: LanguageHelper.string("help_troubleshooting_3_q"),
                            answer: LanguageHelper.string("help_troubleshooting_3_a")
                        )
                    }
                    
                    // 추가 도움
                    VStack(alignment: .leading, spacing: 16) {
                        Divider()
                            .padding(.vertical, 8)
                        
                        Text(LanguageHelper.string("help_additional_help_title"))
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LanguageHelper.string("help_additional_help_desc"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        
                        // App Version Info
                        HStack {
                            Spacer()
                            VStack(spacing: 4) {
                                Text(LanguageHelper.string("help_version"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(LanguageHelper.string("help_copyright"))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
            .navigationTitle(LanguageHelper.string("help_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LanguageHelper.string("done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct HelpCategory<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
        }
        .padding()
        .background(color.opacity(0.05))
        .cornerRadius(12)
    }
}

struct FAQSection: View {
    let question: String
    let answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text(question)
                    .font(.headline)
            }
            
            Text(answer)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.leading, 32)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Features Content View

struct FeaturesContentView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 3D DNA 시각화
                    FeatureCard(
                        title: LanguageHelper.string("features_3d_viz_title"),
                        icon: "cube.fill",
                        color: .blue,
                        features: [
                            LanguageHelper.string("features_3d_viz_1"),
                            LanguageHelper.string("features_3d_viz_2"),
                            LanguageHelper.string("features_3d_viz_3"),
                            LanguageHelper.string("features_3d_viz_4")
                        ]
                    )
                    
                    // 유전자 라이브러리
                    FeatureCard(
                        title: LanguageHelper.string("features_gene_lib_title"),
                        icon: "books.vertical.fill",
                        color: .purple,
                        features: [
                            LanguageHelper.string("features_gene_lib_1"),
                            LanguageHelper.string("features_gene_lib_2"),
                            LanguageHelper.string("features_gene_lib_3"),
                            LanguageHelper.string("features_gene_lib_4")
                        ]
                    )
                    
                    // 분석 도구
                    FeatureCard(
                        title: LanguageHelper.string("features_analysis_title"),
                        icon: "chart.bar.fill",
                        color: .green,
                        features: [
                            LanguageHelper.string("features_analysis_1"),
                            LanguageHelper.string("features_analysis_2"),
                            LanguageHelper.string("features_analysis_3"),
                            LanguageHelper.string("features_analysis_4"),
                            LanguageHelper.string("features_analysis_5"),
                            LanguageHelper.string("features_analysis_6")
                        ]
                    )
                    
                    // 제한 효소 기능
                    FeatureCard(
                        title: LanguageHelper.string("features_enzyme_title"),
                        icon: "scissors",
                        color: .orange,
                        features: [
                            LanguageHelper.string("features_enzyme_1"),
                            LanguageHelper.string("features_enzyme_2"),
                            LanguageHelper.string("features_enzyme_3"),
                            LanguageHelper.string("features_enzyme_4"),
                            LanguageHelper.string("features_enzyme_5"),
                            LanguageHelper.string("features_enzyme_6")
                        ]
                    )
                    
                    // 색상 테마
                    FeatureCard(
                        title: LanguageHelper.string("features_color_title"),
                        icon: "paintpalette.fill",
                        color: .pink,
                        features: [
                            LanguageHelper.string("features_color_1"),
                            LanguageHelper.string("features_color_2"),
                            LanguageHelper.string("features_color_3"),
                            LanguageHelper.string("features_color_4")
                        ]
                    )
                    
                    // 인터랙션 기능
                    FeatureCard(
                        title: LanguageHelper.string("features_interaction_title"),
                        icon: "hand.tap.fill",
                        color: .teal,
                        features: [
                            LanguageHelper.string("features_interaction_1"),
                            LanguageHelper.string("features_interaction_2"),
                            LanguageHelper.string("features_interaction_3"),
                            LanguageHelper.string("features_interaction_4"),
                            LanguageHelper.string("features_interaction_5"),
                            LanguageHelper.string("features_interaction_6")
                        ]
                    )
                    
                    // 성능 최적화
                    FeatureCard(
                        title: LanguageHelper.string("features_performance_title"),
                        icon: "speedometer",
                        color: .indigo,
                        features: [
                            LanguageHelper.string("features_performance_1"),
                            LanguageHelper.string("features_performance_2"),
                            LanguageHelper.string("features_performance_3"),
                            LanguageHelper.string("features_performance_4"),
                            LanguageHelper.string("features_performance_5")
                        ]
                    )
                    
                    // 교육적 기능
                    FeatureCard(
                        title: LanguageHelper.string("features_education_title"),
                        icon: "graduationcap.fill",
                        color: .red,
                        features: [
                            LanguageHelper.string("features_education_1"),
                            LanguageHelper.string("features_education_2"),
                            LanguageHelper.string("features_education_3"),
                            LanguageHelper.string("features_education_4"),
                            LanguageHelper.string("features_education_5")
                        ]
                    )
                }
                .padding()
            }
            .navigationTitle(LanguageHelper.string("features_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LanguageHelper.string("done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureCard: View {
    let title: String
    let icon: String
    let color: Color
    let features: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(color.opacity(0.15))
                    )
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            // Features list
            VStack(alignment: .leading, spacing: 10) {
                ForEach(features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body)
                            .foregroundColor(color)
                        
                        Text(feature)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Privacy Policy Content View

struct PrivacyContentView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        PrivacySection(
                            title: LanguageHelper.string("privacy_section_1_title"),
                            content: LanguageHelper.string("privacy_section_1_content")
                        )
                        
                        PrivacySection(
                            title: LanguageHelper.string("privacy_section_2_title"),
                            content: LanguageHelper.string("privacy_section_2_content")
                        )
                        
                        PrivacySection(
                            title: LanguageHelper.string("privacy_section_3_title"),
                            content: LanguageHelper.string("privacy_section_3_content")
                        )
                        
                        PrivacySection(
                            title: LanguageHelper.string("privacy_section_4_title"),
                            content: LanguageHelper.string("privacy_section_4_content")
                        )
                        
                        PrivacySection(
                            title: LanguageHelper.string("privacy_section_5_title"),
                            content: LanguageHelper.string("privacy_section_5_content")
                        )
                        
                        PrivacySection(
                            title: LanguageHelper.string("privacy_section_6_title"),
                            content: LanguageHelper.string("privacy_section_6_content")
                        )
                    }
                }
                .padding()
            }
            .navigationTitle(LanguageHelper.string("menu_privacy"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LanguageHelper.string("done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PrivacySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Terms of Service Content View

struct TermsContentView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        TermsSection(
                            title: LanguageHelper.string("terms_section_1_title"),
                            content: LanguageHelper.string("terms_section_1_content")
                        )
                        
                        TermsSection(
                            title: LanguageHelper.string("terms_section_2_title"),
                            content: LanguageHelper.string("terms_section_2_content")
                        )
                        
                        TermsSection(
                            title: LanguageHelper.string("terms_section_3_title"),
                            content: LanguageHelper.string("terms_section_3_content")
                        )
                        
                        TermsSection(
                            title: LanguageHelper.string("terms_section_4_title"),
                            content: LanguageHelper.string("terms_section_4_content")
                        )
                        
                        TermsSection(
                            title: LanguageHelper.string("terms_section_5_title"),
                            content: LanguageHelper.string("terms_section_5_content")
                        )
                        
                        TermsSection(
                            title: LanguageHelper.string("terms_section_6_title"),
                            content: LanguageHelper.string("terms_section_6_content")
                        )
                        
                        TermsSection(
                            title: LanguageHelper.string("terms_section_7_title"),
                            content: LanguageHelper.string("terms_section_7_content")
                        )
                        
                        TermsSection(
                            title: LanguageHelper.string("terms_section_8_title"),
                            content: LanguageHelper.string("terms_section_8_content")
                        )
                        
                        TermsSection(
                            title: LanguageHelper.string("terms_section_9_title"),
                            content: LanguageHelper.string("terms_section_9_content")
                        )
                    }
                }
                .padding()
            }
            .navigationTitle(LanguageHelper.string("menu_terms"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LanguageHelper.string("done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TermsSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - License Content View

struct LicenseContentView: View {
    @Environment(\.dismiss) var dismiss
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    private var appName: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "DNAViewer"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // MIT 라이센스 헤더
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LanguageHelper.string("license_copyright"))
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // 라이센스 본문
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LanguageHelper.string("license_permission_text"))
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(LanguageHelper.string("license_notice_text"))
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(LanguageHelper.string("license_warranty_text"))
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Divider()
                    
                    // 오픈소스 라이브러리
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LanguageHelper.string("license_open_source"))
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            LibraryItem(
                                name: "SceneKit",
                                description: LanguageHelper.string("license_scenekit_desc"),
                                license: LanguageHelper.string("license_apple_license")
                            )
                            
                            LibraryItem(
                                name: "SwiftUI",
                                description: LanguageHelper.string("license_swiftui_desc"),
                                license: LanguageHelper.string("license_apple_license")
                            )
                            
                            LibraryItem(
                                name: "Charts",
                                description: LanguageHelper.string("license_charts_desc"),
                                license: LanguageHelper.string("license_apple_license")
                            )
                            
                            LibraryItem(
                                name: "NCBI E-utilities",
                                description: LanguageHelper.string("license_ncbi_desc"),
                                license: LanguageHelper.string("license_public_domain")
                            )
                        }
                    }
                    
                    Divider()
                    
                    // 앱 정보
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LanguageHelper.string("license_app_info"))
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            LicenseInfoRow(
                                title: LanguageHelper.string("license_app_name_title"),
                                value: appName,
                                description: LanguageHelper.string("license_app_name_desc")
                            )
                            LicenseInfoRow(
                                title: LanguageHelper.string("license_version_title"),
                                value: appVersion,
                                description: LanguageHelper.string("license_version_desc")
                            )
                            LicenseInfoRow(
                                title: LanguageHelper.string("license_build_title"),
                                value: buildNumber,
                                description: LanguageHelper.string("license_build_desc")
                            )
                            LicenseInfoRow(
                                title: LanguageHelper.string("license_platform_title"),
                                value: "iOS 15.0+",
                                description: LanguageHelper.string("license_platform_desc")
                            )
                            LicenseInfoRow(
                                title: LanguageHelper.string("license_last_update_title"),
                                value: "2025년 10월",
                                description: LanguageHelper.string("license_last_update_desc")
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(LanguageHelper.string("menu_license"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LanguageHelper.string("done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LibraryItem: View {
    let name: String
    let description: String
    let license: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(license)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct LicenseInfoRow: View {
    let title: String
    let value: String
    let description: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    ViewerView(sequence: DNASequence(
        name: "Sample Gene",
        sequence: "ATGCGATCGATCGATCGATCGATCG",
        summary: "A sample DNA sequence"
    ), viewModel: DNAViewModel())
}

