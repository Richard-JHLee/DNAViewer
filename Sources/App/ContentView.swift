//
//  ContentView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DNAViewModel()
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            // 메인 앱 컨텐츠
            Group {
                if let sequence = viewModel.currentSequence {
                    // DNA 시퀀스가 로드되면 ViewerView 표시
                    ViewerView(sequence: sequence, viewModel: viewModel)
                        .id(sequence.id) // sequence가 변경되면 ViewerView를 재생성
                } else {
                    // 로딩 중이거나 에러 발생
                    VStack(spacing: 20) {
                        if viewModel.isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                
                                Text("Loading DNA sequence...")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if !viewModel.loadingProgress.isEmpty {
                                    Text(viewModel.loadingProgress)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                            }
                        } else {
                            VStack(spacing: 16) {
                                        Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 60))
                                    .foregroundColor(.blue)
                                
                                Text("DNA Viewer")
                                    .font(.largeTitle.weight(.bold))
                                    .foregroundColor(.primary)
                                
                                Text("Loading default sequence...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    #if os(macOS)
                    .background(Color(NSColor.windowBackgroundColor))
                    #else
                    .background(Color(.systemBackground))
                    #endif
                }
            }
            
            // 스플래시 화면
            if showSplash {
                DNASplashScreenView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            print("🚀 ContentView onAppear")
            
            // 기본 DNA 시퀀스 로드
            if viewModel.currentSequence == nil {
                viewModel.loadDefaultSequence()
            }
            
            // 스플래시 화면을 2초 후에 숨김
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("Retry") {
                viewModel.loadDefaultSequence()
            }
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error ?? "")
        }
    }
}

// MARK: - Splash Screen View
struct DNASplashScreenView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // 배경
            #if os(macOS)
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()
            #else
            Color(.systemBackground)
                .ignoresSafeArea()
            #endif
            
            VStack(spacing: 30) {
                // DNA 로고
                ZStack {
                    // 배경 원
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue.opacity(0.1), .purple.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                    
                    // DNA 이중나선 아이콘
                                        Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                // 앱 이름
                VStack(spacing: 8) {
                    Text("DNA Viewer")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .opacity(textOpacity)
                    
                    Text("Explore Genetic Information")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .opacity(textOpacity)
                }
                
                // 로딩 인디케이터
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.blue)
                        .opacity(textOpacity)
                    
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .opacity(textOpacity)
                }
            }
        }
        .onAppear {
            // 애니메이션 시작
            withAnimation(.easeOut(duration: 0.8)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                textOpacity = 1.0
            }
        }
    }
}

#Preview {
    ContentView()
}

