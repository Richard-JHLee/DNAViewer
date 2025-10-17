//
//  SequenceBar.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import SwiftUI

struct SequenceBar: View {
    let sequence: String
    @Binding var selectedRange: Range<Int>?
    @ObservedObject var sceneManager: DNASceneManager
    
    @State private var scrollPosition: Int = 0
    
    var body: some View {
        let _ = print("🎨 SequenceBar rendering: currentGroup=\(sceneManager.currentGroup), groupSize=\(sceneManager.groupSize)")
        
        return VStack(spacing: 4) {
            // Position indicator
            HStack {
                Text("Position: \(scrollPosition)")
                    .font(.caption2)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(sequence.count) bp")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            
            // Sequence scroll view with group buttons on top
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 2) {
                    ForEach(Array(sequence.enumerated()), id: \.offset) { index, base in
                        VStack(spacing: 2) {
                            // Group button at the start of each group
                            if shouldShowGroupButton(at: index) {
                                GroupButton(
                                    groupNumber: getGroupNumber(for: index),
                                    isSelected: getGroupNumber(for: index) == sceneManager.currentGroup,
                                    onTap: { group in
                                        sceneManager.loadGroup(group)
                                    }
                                )
                            } else {
                                Spacer()
                                    .frame(height: 40)
                            }
                            
                            // Base cell
                            BaseCell(
                                base: base,
                                index: index,
                                isSelected: isSelected(index),
                                isInCurrentGroup: isInCurrentGroup(index)
                            )
                            .onTapGesture {
                                print("👉 BaseCell tapped at index: \(index), base: \(base)")
                                
                                // Toggle selection
                                if let range = selectedRange, range.contains(index) {
                                    // Already selected - deselect
                                    print("🔓 Deselecting base at index: \(index)")
                                    selectedRange = nil
                                    sceneManager.selectedBaseIndex = nil
                                    sceneManager.clearHighlights()
                                } else {
                                    // Select new base
                                    print("🔒 Selecting base at index: \(index)")
                                    
                                    // Calculate which group this base belongs to
                                    let targetGroup = getGroupNumber(for: index)
                                    print("📍 Base at index \(index) belongs to group \(targetGroup)")
                                    
                                    // Switch to the target group if needed
                                    if targetGroup != sceneManager.currentGroup {
                                        print("🔄 Switching from group \(sceneManager.currentGroup) to group \(targetGroup)")
                                        sceneManager.loadGroup(targetGroup)
                                        
                                        // Wait a bit for the scene to rebuild, then select the base
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            selectedRange = index..<(index + 1)
                                            sceneManager.selectBase(at: index)
                                        }
                                    } else {
                                        // Same group - select immediately
                                        selectedRange = index..<(index + 1)
                                        sceneManager.selectBase(at: index)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.8))
    }
    
    private func isSelected(_ index: Int) -> Bool {
        guard let range = selectedRange else { return false }
        return range.contains(index)
    }
    
    private func shouldShowGroupButton(at index: Int) -> Bool {
        // Show group button only at the start of each group
        return index % sceneManager.groupSize == 0
    }
    
    private func getGroupNumber(for index: Int) -> Int {
        // Calculate which group this index belongs to
        return (index / sceneManager.groupSize) + 1
    }
    
    private func isInCurrentGroup(_ index: Int) -> Bool {
        // Check if this index belongs to the current group
        return getGroupNumber(for: index) == sceneManager.currentGroup
    }
}

struct BaseCell: View {
    let base: Character
    let index: Int
    let isSelected: Bool
    let isInCurrentGroup: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            // Position number (every 10)
            if index % 10 == 0 {
                Text("\(index)")
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.6))
            } else {
                Text(" ")
                    .font(.system(size: 8))
            }
            
            // Base letter
            Text(String(base))
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 20, height: 24)
                .background(colorForBase(base))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return .blue  // 개별 선택: 파란색
        } else if isInCurrentGroup {
            return .white   // 현재 그룹: 흰색
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        if isSelected {
            return 3  // 개별 선택: 더 두꺼운 테두리
        } else if isInCurrentGroup {
            return 2  // 현재 그룹: 두꺼운 테두리
        } else {
            return 0
        }
    }
    
    private func colorForBase(_ base: Character) -> Color {
        switch base {
        case "A": return .orange  // 3D 모형과 일치 (주황색)
        case "T": return .green   // 3D 모형과 일치 (초록색)
        case "G": return .red     // 3D 모형과 일치 (빨간색)
        case "C": return .yellow  // 3D 모형과 일치 (노란색)
        default: return .gray
        }
    }
}

struct GroupButton: View {
    let groupNumber: Int
    let isSelected: Bool
    let onTap: (Int) -> Void
    
    var body: some View {
        let _ = print("🔘 GroupButton G\(groupNumber): isSelected=\(isSelected)")
        
        return Button(action: {
            print("👆 GroupButton G\(groupNumber) tapped!")
            onTap(groupNumber)
        }) {
            Text("G\(groupNumber)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minWidth: 44)
                .background(
                    isSelected ? Color.blue : Color.gray.opacity(0.6)
                )
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: isSelected ? 2 : 0)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let manager = DNASceneManager()
    return SequenceBar(
        sequence: "ATGCGATCGATCGATCGATCGATCGATCGATCG",
        selectedRange: .constant(5..<10),
        sceneManager: manager
    )
    .frame(height: 120)
    .background(Color.black)
}

