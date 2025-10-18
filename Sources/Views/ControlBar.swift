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
            
            // Representation Controls (collapsible)
            if showStyleAndColor {
                VStack(spacing: 16) {
                    // Style Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Style")
                            .font(.title2)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 8) {
                            ForEach(DNARepresentation.allCases, id: \.self) { rep in
                                Button(action: {
                                    sceneManager.currentRepresentation = rep
                                    sceneManager.rebuildScene()
                                }) {
                                    Text(rep.rawValue)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(
                                            sceneManager.currentRepresentation == rep ?
                                                Color.blue : Color.gray.opacity(0.3)
                                        )
                                        .cornerRadius(12)
                                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                }
                            }
                        }
                    }
                    
                    // Color Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.title2)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 8) {
                            ForEach(DNAColorScheme.allCases, id: \.self) { scheme in
                                Button(action: {
                                    sceneManager.colorScheme = scheme
                                    sceneManager.rebuildScene()
                                }) {
                                    Text(scheme.rawValue)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(
                                            sceneManager.colorScheme == scheme ?
                                                Color.green : Color.gray.opacity(0.3)
                                        )
                                        .cornerRadius(12)
                                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                }
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
                .fill(Color.black.opacity(0.85))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
    }
}

#Preview {
    ControlBar(sceneManager: DNASceneManager(), showStyleAndColor: .constant(true))
        .background(Color.gray)
}

