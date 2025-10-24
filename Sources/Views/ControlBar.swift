//
//  ControlBar.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import SwiftUI

struct ControlBar: View {
    @ObservedObject var sceneManager: DNASceneManager
    @Binding var showStyleAndColor: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with close button
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Controls")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        showStyleAndColor = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 4)
            
            // Representation Controls (collapsible)
            if showStyleAndColor {
                VStack(spacing: 16) {
                    // Style Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "cube.transparent.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                            Text("Style")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 8) {
                            ForEach([DNARepresentation.doubleHelix, .ladder2D, .genomeMap], id: \.self) { rep in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        sceneManager.currentRepresentation = rep
                                        sceneManager.rebuildScene()
                                    }
                                }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: rep.iconName)
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                        
                                        Text(rep.rawValue)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                        
                                        Text(rep.description)
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.7))
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                sceneManager.currentRepresentation == rep ?
                                                    LinearGradient(
                                                        colors: [Color.blue, Color.blue.opacity(0.7)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ) :
                                                    LinearGradient(
                                                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .strokeBorder(
                                                        sceneManager.currentRepresentation == rep ? 
                                                            Color.blue.opacity(0.8) : Color.clear,
                                                        lineWidth: 2
                                                    )
                                            )
                                    )
                                    .scaleEffect(sceneManager.currentRepresentation == rep ? 1.05 : 1.0)
                                    .shadow(
                                        color: sceneManager.currentRepresentation == rep ? 
                                            Color.blue.opacity(0.5) : Color.clear,
                                        radius: 8
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: sceneManager.currentRepresentation)
                            }
                        }
                    }
                    
                    // Divider
                    Divider()
                        .background(Color.white.opacity(0.3))
                        .padding(.vertical, 4)
                    
                    // Color Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "paintpalette.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                            Text("Color")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 8) {
                            ForEach(DNAColorScheme.allCases, id: \.self) { scheme in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        // 스타일을 강제로 Double Helix로 고정 (다른 스타일이 선택돼 있을 때 대비)
                                        if sceneManager.currentRepresentation != .doubleHelix {
                                            sceneManager.currentRepresentation = .doubleHelix
                                        }
                                        sceneManager.colorScheme = scheme
                                        sceneManager.rebuildScene()
                                    }
                                }) {
                                    VStack(spacing: 6) {
                                        // Color preview
                                        HStack(spacing: 3) {
                                            ForEach(scheme.previewColors, id: \.self) { color in
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(color)
                                                    .frame(width: 16, height: 20)
                                            }
                                        }
                                        
                                        Text(scheme.rawValue)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                        
                                        Text(scheme.description)
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.7))
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                sceneManager.colorScheme == scheme ?
                                                    LinearGradient(
                                                        colors: [Color.green, Color.green.opacity(0.7)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ) :
                                                    LinearGradient(
                                                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .strokeBorder(
                                                        sceneManager.colorScheme == scheme ? 
                                                            Color.green.opacity(0.8) : Color.clear,
                                                        lineWidth: 2
                                                    )
                                            )
                                    )
                                    .scaleEffect(sceneManager.colorScheme == scheme ? 1.05 : 1.0)
                                    .shadow(
                                        color: sceneManager.colorScheme == scheme ? 
                                            Color.green.opacity(0.5) : Color.clear,
                                        radius: 8
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: sceneManager.colorScheme)
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // Group Navigation (for sequences with multiple groups) - disabled
            // if sceneManager.totalGroups > 1 {
            //     HStack(spacing: 8) {
            //         Button(action: {
            //             sceneManager.previousGroup()
            //         }) {
            //             Image(systemName: "chevron.left")
            //                 .font(.title2)
            //                 .foregroundColor(.white)
            //                 .frame(width: 36, height: 36)
            //                 .background(Color.blue.opacity(0.7))
            //                 .clipShape(Circle())
            //         }
            //         .disabled(sceneManager.currentGroup <= 1)
                    
            //         // Decorative spacer with subtle indicator
            //         HStack(spacing: 4) {
            //             ForEach(0..<3, id: \.self) { _ in
            //                 Circle()
            //                     .fill(Color.white.opacity(0.3))
            //                     .frame(width: 4, height: 4)
            //             }
            //         }
            //         .padding(.horizontal, 8)
                    
            //         Button(action: {
            //             sceneManager.nextGroup()
            //         }) {
            //             Image(systemName: "chevron.right")
            //                 .font(.title2)
            //                 .foregroundColor(.white)
            //                 .frame(width: 36, height: 36)
            //                 .background(Color.blue.opacity(0.7))
            //                 .clipShape(Circle())
            //         }
            //         .disabled(sceneManager.currentGroup >= sceneManager.totalGroups)
            //     }
            // }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.7))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
    }
}

#Preview {
    ControlBar(sceneManager: DNASceneManager(), showStyleAndColor: .constant(true))
        .background(Color.gray)
}

