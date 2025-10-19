//
//  DNABottomMenu.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-18.
//

import SwiftUI

struct DNABottomMenu: View {
    let onSequence: () -> Void
    let onRotation: () -> Void
    let onScissor: () -> Void
    let onCloning: () -> Void
    let onAnalysis: () -> Void
    let onReload: () -> Void
    let onDigest: () -> Void
    let showDigest: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Sequence button
            BottomMenuButton(
                icon: "textformat.abc",
                title: "Sequence",
                action: onSequence
            )
            
            // Rotation button
            BottomMenuButton(
                icon: "arrow.clockwise",
                title: "Rotation",
                action: onRotation
            )
            
            // Scissor button
            BottomMenuButton(
                icon: "scissors",
                title: "Scissor",
                action: onScissor
            )
            
            // Cloning button
            BottomMenuButton(
                icon: "arrow.triangle.branch",
                title: "Cloning",
                action: onCloning
            )
            
            // Analysis button
            BottomMenuButton(
                icon: "chart.bar.fill",
                title: "Analysis",
                action: onAnalysis
            )
            
            // Reload button
            BottomMenuButton(
                icon: "arrow.counterclockwise.circle.fill",
                title: "Reload",
                action: onReload
            )
            
            // Digest button - only show when cut sites are highlighted
            if showDigest {
                BottomMenuButton(
                    icon: "scissors.badge.ellipsis",
                    title: "Digest",
                    action: onDigest
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
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

#Preview {
    DNABottomMenu(
        onSequence: {},
        onRotation: {},
        onScissor: {},
        onCloning: {},
        onAnalysis: {},
        onReload: {},
        onDigest: {},
        showDigest: true
    )
    .background(Color.gray.opacity(0.1))
}
