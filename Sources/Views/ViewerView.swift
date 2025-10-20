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
                    GuideSection(title: "🚀 시작하기", color: .green) {
                        GuideItem(title: "기본 DNA 시퀀스 보기", description: "앱 시작 시 기본 DNA 시퀀스(BRCA1)가 로드됩니다. 드래그로 회전, 핀치로 확대/축소하세요.")
                        GuideItem(title: "그룹별 탐색", description: "DNA는 100bp 단위로 그룹화됩니다. G1, G2, G3... 버튼으로 섹션을 이동하세요.")
                        GuideItem(title: "시퀀스 읽기", description: "'Sequence' 버튼으로 하단에 염기서열(A, T, G, C)을 표시합니다.")
                        GuideItem(title: "3D 스타일 변경", description: "눈 아이콘(👁)으로 Double Helix, Ladder, Ball & Stick 등 다양한 3D 모드를 선택하세요.")
                    }
                    
                    // 유전자 라이브러리
                    GuideSection(title: "📚 유전자 라이브러리", color: .purple) {
                        GuideItem(title: "라이브러리 열기", description: "메뉴(☰) → Gene Library로 NCBI 데이터베이스의 유전자를 탐색하세요.")
                        GuideItem(title: "카테고리별 검색", description: "Organism, Gene Type, Chromosome, Status, Gene Family로 필터링하세요.")
                        GuideItem(title: "유전자 적용", description: "유전자 선택 후 'Apply'로 해당 DNA 시퀀스를 3D로 로드합니다.")
                        GuideItem(title: "실시간 데이터", description: "모든 데이터는 NCBI에서 실시간으로 가져오므로 항상 최신입니다.")
                    }
                    
                    // 분석 도구
                    GuideSection(title: "📊 분석 도구", color: .blue) {
                        GuideItem(title: "GC 함량", description: "구아닌(G)과 시토신(C)의 비율을 분석합니다. 높은 GC 함량은 안정적인 DNA를 의미합니다.")
                        GuideItem(title: "CpG 아일랜드", description: "CG 빈도가 높은 영역을 탐지합니다. 유전자 조절에 중요한 역할을 합니다.")
                        GuideItem(title: "제한 효소", description: "DNA 절단 가능한 효소들을 분석하고 절단 위치를 확인합니다.")
                        GuideItem(title: "단백질 번역", description: "DNA를 아미노산으로 번역하고, ORF를 찾고, 아미노산 조성을 분석합니다.")
                    }
                    
                    // 제한 효소
                    GuideSection(title: "✂️ 제한 효소", color: .orange) {
                        GuideItem(title: "효소 선택", description: "Scissor 버튼으로 현재 시퀀스에 사용 가능한 제한 효소 목록을 확인하세요.")
                        GuideItem(title: "3D 시각화", description: "'Show 3D'로 절단 위치를 3D에서 빨간 마커로 표시합니다.")
                        GuideItem(title: "가상 절단", description: "'Digest' 버튼으로 DNA 절단을 시뮬레이션하고 단편을 확인하세요.")
                        GuideItem(title: "교육적 활용", description: "각 효소의 인식 서열과 절단 패턴을 학습할 수 있습니다.")
                    }
                    
                    // 사용 팁
                    GuideSection(title: "💡 사용 팁", color: .yellow) {
                        GuideItem(title: "회전", description: "3D 뷰를 드래그하여 DNA 구조를 자유롭게 회전시키세요.")
                        GuideItem(title: "확대/축소", description: "핀치 제스처로 3D 구조를 확대하거나 축소하세요.")
                        GuideItem(title: "자동 회전", description: "Rotation 버튼으로 DNA를 360도 자동 회전시킵니다.")
                        GuideItem(title: "뷰 초기화", description: "Reload 버튼으로 카메라를 기본 위치로 재설정합니다.")
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
                    // Subtitle
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LanguageHelper.string("help_subtitle"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)
                    
                    // 일반 사용
                    HelpCategory(title: "일반 사용", icon: "questionmark.circle.fill", color: .blue) {
                        FAQSection(
                            question: "DNA 시퀀스를 어떻게 로드하나요?",
                            answer: "메뉴(☰)에서 Gene Library를 선택하고 원하는 유전자를 검색한 후 'Apply' 버튼을 누르세요. NCBI 데이터베이스에서 실시간으로 데이터를 가져옵니다."
                        )
                        
                        FAQSection(
                            question: "앱이 느리게 실행됩니다",
                            answer: "대용량 DNA 시퀀스의 경우 로딩 시간이 오래 걸릴 수 있습니다. 그룹 단위(100bp)로 나누어 표시하므로 각 그룹 전환 시 잠시 기다려주세요."
                        )
                        
                        FAQSection(
                            question: "시퀀스 정보는 어디서 확인하나요?",
                            answer: "상단의 Info 버튼(ℹ️)을 누르면 현재 DNA 시퀀스의 상세 정보(이름, 길이, 염색체, 생물체 등)를 확인할 수 있습니다."
                        )
                    }
                    
                    // 3D 시각화
                    HelpCategory(title: "3D 시각화", icon: "cube.fill", color: .purple) {
                        FAQSection(
                            question: "3D 뷰가 움직이지 않아요",
                            answer: "드래그 제스처로 회전, 핀치 제스처로 확대/축소하세요. Reload 버튼(↻)으로 초기 상태로 되돌릴 수 있습니다."
                        )
                        
                        FAQSection(
                            question: "3D 스타일을 변경하려면?",
                            answer: "눈 아이콘(👁) 버튼을 누르면 Style 섹션이 나타납니다. Double Helix, Ladder, Ball & Stick 중 원하는 스타일을 선택하세요."
                        )
                        
                        FAQSection(
                            question: "색상이 변경되지 않습니다",
                            answer: "눈 아이콘(👁) 버튼을 누르고 Color 섹션에서 원하는 색상 테마를 선택하세요. Classic, Vivid, Pastel, Neon 등 다양한 테마가 있습니다."
                        )
                        
                        FAQSection(
                            question: "자동 회전은 어떻게 하나요?",
                            answer: "Bottom menu에서 Rotation 버튼을 누르면 DNA가 360도 자동으로 회전합니다. 다시 누르면 정지합니다."
                        )
                    }
                    
                    // 분석 도구
                    HelpCategory(title: "분석 도구", icon: "chart.bar.fill", color: .green) {
                        FAQSection(
                            question: "GC 함량이란 무엇인가요?",
                            answer: "구아닌(G)과 시토신(C) 염기의 비율입니다. 높은 GC 함량은 더 안정적인 DNA 구조를 의미하며, 유전자 발현과 진화 연구에 중요합니다."
                        )
                        
                        FAQSection(
                            question: "CpG 아일랜드는 왜 중요한가요?",
                            answer: "CpG 아일랜드는 CG 디뉴클레오티드가 풍부한 영역으로, 유전자의 프로모터 부위에 많이 위치합니다. DNA 메틸화를 통한 유전자 조절에 핵심적인 역할을 합니다."
                        )
                        
                        FAQSection(
                            question: "단백질 번역 결과는 어떻게 보나요?",
                            answer: "Analysis 메뉴에서 'Protein' 탭을 선택하세요. DNA가 자동으로 아미노산으로 번역되며, 코돈별 상세 정보와 ORF(Open Reading Frame)를 확인할 수 있습니다."
                        )
                        
                        FAQSection(
                            question: "아미노산 조성 그래프는 무엇인가요?",
                            answer: "번역된 단백질에 포함된 각 아미노산의 개수와 비율을 막대그래프로 보여줍니다. 색상은 아미노산의 화학적 특성(소수성, 극성, 전하)을 나타냅니다."
                        )
                    }
                    
                    // 제한 효소
                    HelpCategory(title: "제한 효소", icon: "scissors", color: .orange) {
                        FAQSection(
                            question: "제한 효소 절단 위치가 안 보여요",
                            answer: "Bottom menu의 Scissor 버튼을 누르고, 원하는 제한 효소를 선택한 후 'Show 3D' 버튼을 눌러주세요. 3D 뷰에 빨간색 마커가 표시됩니다."
                        )
                        
                        FAQSection(
                            question: "여러 효소를 동시에 선택할 수 있나요?",
                            answer: "네! 여러 제한 효소를 선택하면 모든 절단 위치가 함께 표시됩니다. 'Digest' 버튼으로 가상 절단 시뮬레이션도 가능합니다."
                        )
                        
                        FAQSection(
                            question: "절단 마커를 제거하려면?",
                            answer: "Bottom menu의 Reload 버튼(↻)을 누르면 모든 하이라이트와 마커가 제거되고 초기 상태로 돌아갑니다."
                        )
                        
                        FAQSection(
                            question: "SequenceBar에 scissors 아이콘이 나타납니다",
                            answer: "이것은 해당 위치가 제한 효소 절단 위치임을 나타냅니다. 빨간색 테두리와 함께 표시되어 정확한 절단 위치를 쉽게 확인할 수 있습니다."
                        )
                    }
                    
                    // 성능 및 문제 해결
                    HelpCategory(title: "문제 해결", icon: "wrench.and.screwdriver.fill", color: .red) {
                        FAQSection(
                            question: "앱이 멈추거나 응답하지 않습니다",
                            answer: "매우 큰 DNA 시퀀스의 경우 3D 렌더링에 시간이 걸릴 수 있습니다. Reload 버튼을 눌러 초기화하거나, 앱을 재시작해보세요."
                        )
                        
                        FAQSection(
                            question: "Gene Library에서 유전자를 찾을 수 없어요",
                            answer: "인터넷 연결을 확인하고, 정확한 유전자 이름이나 심볼을 입력했는지 확인하세요. NCBI 데이터베이스에 등록된 유전자만 검색 가능합니다."
                        )
                        
                        FAQSection(
                            question: "분석 결과를 저장할 수 있나요?",
                            answer: "현재 버전에서는 화면 캡처(스크린샷)로 분석 결과를 저장할 수 있습니다. 향후 업데이트에서 데이터 내보내기 기능이 추가될 예정입니다."
                        )
                    }
                    
                    // 추가 도움
                    VStack(alignment: .leading, spacing: 16) {
                        Divider()
                            .padding(.vertical, 8)
                        
                        Text("추가 도움이 필요합니다")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("문제가 지속되거나 다른 질문이 있으시면 앱 정보 페이지의 문의 정보를 통해 연락해주세요.")
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
                                Text("DNA Viewer v1.0")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("© 2025 AVAS. All rights reserved")
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
                    // Subtitle
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LanguageHelper.string("features_subtitle"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)
                    
                    // 3D DNA 시각화
                    FeatureCard(
                        title: "3D DNA 시각화",
                        icon: "cube.fill",
                        color: .blue,
                        features: [
                            "SceneKit 기반 고품질 3D 렌더링",
                            "실시간 인터랙티브 조작 (회전, 확대/축소)",
                            "Double Helix, Ladder, Ball & Stick 스타일 지원",
                            "그룹별 염기서열 탐색 (100bp 단위)"
                        ]
                    )
                    
                    // 유전자 라이브러리
                    FeatureCard(
                        title: "유전자 라이브러리",
                        icon: "books.vertical.fill",
                        color: .purple,
                        features: [
                            "NCBI 데이터베이스 실시간 연동",
                            "카테고리별 유전자 검색 및 필터링",
                            "Organism, Gene Type, Chromosome 등 분류",
                            "FASTA 형식 DNA 시퀀스 자동 로드"
                        ]
                    )
                    
                    // 분석 도구
                    FeatureCard(
                        title: "분석 도구",
                        icon: "chart.bar.fill",
                        color: .green,
                        features: [
                            "GC 함량 분석 및 윈도우 플롯",
                            "CpG 아일랜드 자동 탐지",
                            "제한 효소 절단 부위 분석",
                            "DNA → 단백질 번역 (코돈 테이블)",
                            "아미노산 조성 막대그래프",
                            "Open Reading Frame (ORF) 탐지"
                        ]
                    )
                    
                    // 제한 효소 기능
                    FeatureCard(
                        title: "제한 효소",
                        icon: "scissors",
                        color: .orange,
                        features: [
                            "200+ 제한 효소 데이터베이스",
                            "IUPAC 코드 지원 (정규표현식 변환)",
                            "절단 위치 3D 시각화 (빨간 마커)",
                            "SequenceBar scissors 아이콘 표시",
                            "가상 DNA 절단 시뮬레이션",
                            "교육용 Gel Electrophoresis 시각화"
                        ]
                    )
                    
                    // 색상 테마
                    FeatureCard(
                        title: "색상 테마",
                        icon: "paintpalette.fill",
                        color: .pink,
                        features: [
                            "Classic, Vivid, Pastel, Neon 테마",
                            "염기별 색상 커스터마이징 (A, T, G, C)",
                            "수소 결합 색상 설정",
                            "실시간 색상 변경 및 미리보기"
                        ]
                    )
                    
                    // 인터랙션 기능
                    FeatureCard(
                        title: "인터랙션 기능",
                        icon: "hand.tap.fill",
                        color: .teal,
                        features: [
                            "드래그로 3D 모델 회전",
                            "핀치 제스처로 확대/축소",
                            "자동 360도 회전 애니메이션",
                            "개별 염기 선택 및 하이라이트",
                            "그룹 단위 네비게이션",
                            "Reload로 초기 상태 복원"
                        ]
                    )
                    
                    // 성능 최적화
                    FeatureCard(
                        title: "성능 최적화",
                        icon: "speedometer",
                        color: .indigo,
                        features: [
                            "그룹 단위 로딩으로 메모리 효율화",
                            "대용량 DNA 시퀀스 처리 가능",
                            "백그라운드 스레드 3D 렌더링",
                            "스마트 캐싱 시스템",
                            "자동 메모리 정리 (autoreleasepool)"
                        ]
                    )
                    
                    // 교육적 기능
                    FeatureCard(
                        title: "교육적 기능",
                        icon: "graduationcap.fill",
                        color: .red,
                        features: [
                            "분자생물학 실험 시뮬레이션",
                            "DNA 클로닝 프로세스 시각화",
                            "유전자 변환 애니메이션",
                            "실험 검증 과정 학습",
                            "상세한 사용 가이드 제공"
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
                        Text(LanguageHelper.string("license_title"))
                            .font(.title)
                            .fontWeight(.bold)
                        
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
                                description: "Apple의 3D 그래픽 프레임워크",
                                license: "Apple 라이센스"
                            )
                            
                            LibraryItem(
                                name: "SwiftUI",
                                description: "Apple의 선언적 UI 프레임워크",
                                license: "Apple 라이센스"
                            )
                            
                            LibraryItem(
                                name: "Charts",
                                description: "Apple의 데이터 시각화 프레임워크",
                                license: "Apple 라이센스"
                            )
                            
                            LibraryItem(
                                name: "NCBI E-utilities",
                                description: "유전자 데이터베이스 공개 API",
                                license: "퍼블릭 도메인"
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
                                title: "앱 이름",
                                value: appName,
                                description: "애플리케이션 이름"
                            )
                            LicenseInfoRow(
                                title: "버전",
                                value: appVersion,
                                description: "현재 앱 버전"
                            )
                            LicenseInfoRow(
                                title: "빌드",
                                value: buildNumber,
                                description: "빌드 번호"
                            )
                            LicenseInfoRow(
                                title: "플랫폼",
                                value: "iOS 15.0+",
                                description: "최소 지원 iOS 버전"
                            )
                            LicenseInfoRow(
                                title: "마지막 업데이트",
                                value: "2025년 10월",
                                description: "마지막 업데이트 날짜"
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

