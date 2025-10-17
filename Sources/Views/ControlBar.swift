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
        VStack(spacing: 12) {
            
            // Representation Controls (collapsible)
            if showStyleAndColor {
                HStack(spacing: 8) {
                    Text("Style:")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    ForEach(DNARepresentation.allCases, id: \.self) { rep in
                        Button(action: {
                            sceneManager.currentRepresentation = rep
                            sceneManager.rebuildScene()
                        }) {
                            Text(rep.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    sceneManager.currentRepresentation == rep ?
                                        Color.blue : Color.black.opacity(0.5)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
                .transition(.opacity)
                
                // Color Scheme Controls (collapsible)
                HStack(spacing: 8) {
                    Text("Color:")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    ForEach(DNAColorScheme.allCases, id: \.self) { scheme in
                        Button(action: {
                            sceneManager.colorScheme = scheme
                            sceneManager.rebuildScene()
                        }) {
                            Text(scheme.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    sceneManager.colorScheme == scheme ?
                                        Color.green : Color.black.opacity(0.5)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
                .transition(.opacity)
            }
            
            // Group Navigation (for sequences with multiple groups)
            if sceneManager.totalGroups > 1 {
                HStack(spacing: 12) {
                    Button(action: {
                        sceneManager.previousGroup()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.blue.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .disabled(sceneManager.currentGroup <= 1)
                    
                    Text("Group \(sceneManager.currentGroup) of \(sceneManager.totalGroups)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(16)
                    
                    Button(action: {
                        sceneManager.nextGroup()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.blue.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .disabled(sceneManager.currentGroup >= sceneManager.totalGroups)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.8))
    }
}

#Preview {
    ControlBar(sceneManager: DNASceneManager(), showStyleAndColor: .constant(true))
        .background(Color.gray)
}

