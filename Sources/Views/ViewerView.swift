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
    @State private var showUserGuide = false
    @State private var showHelp = false
    
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
        .sheet(isPresented: $showUserGuide) {
            UserGuideContentView()
        }
        .sheet(isPresented: $showHelp) {
            HelpContentView()
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
                            onHelp: { showHelp = true },
                            onSettings: { showSettings = true },
                            onAbout: { 
                                // TODO: About sheet (향후 구현)
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

// MARK: - User Guide Content View

struct UserGuideContentView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DNA Viewer 사용 가이드")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("DNA 시퀀스 분석과 3D 시각화를 위한 완전한 가이드")
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
            .navigationTitle("사용 가이드")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
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
                    Text("도움말 & FAQ")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    FAQSection(question: "DNA 시퀀스를 어떻게 로드하나요?", answer: "메뉴에서 Gene Library를 선택하고 원하는 유전자를 검색한 후 'Apply'를 누르세요.")
                    
                    FAQSection(question: "3D 뷰가 움직이지 않아요", answer: "드래그로 회전, 핀치로 확대/축소하세요. Reload 버튼으로 초기화할 수 있습니다.")
                    
                    FAQSection(question: "제한 효소 절단 위치가 안 보여요", answer: "Scissor 메뉴에서 효소를 선택하고 'Show 3D'를 눌러주세요.")
                    
                    FAQSection(question: "분석 결과를 저장할 수 있나요?", answer: "현재 버전에서는 스크린샷으로 저장하실 수 있습니다.")
                    
                    FAQSection(question: "문의하기", answer: "추가 문의사항은 support@avas.com으로 연락주세요.")
                }
                .padding()
            }
            .navigationTitle("도움말")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
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

#Preview {
    ViewerView(sequence: DNASequence(
        name: "Sample Gene",
        sequence: "ATGCGATCGATCGATCGATCGATCG",
        summary: "A sample DNA sequence"
    ), viewModel: DNAViewModel())
}

