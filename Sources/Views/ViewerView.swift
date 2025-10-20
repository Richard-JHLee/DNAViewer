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
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("도움말 & FAQ")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("자주 묻는 질문과 문제 해결")
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

#Preview {
    ViewerView(sequence: DNASequence(
        name: "Sample Gene",
        sequence: "ATGCGATCGATCGATCGATCGATCG",
        summary: "A sample DNA sequence"
    ), viewModel: DNAViewModel())
}

