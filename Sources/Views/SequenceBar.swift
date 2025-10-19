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
    
    // 현재 그룹의 시퀀스만 추출
    private var currentGroupSequence: String {
        let start = sceneManager.displayStart
        let end = min(start + sceneManager.actualDisplayLength, sequence.count)
        let startIndex = sequence.index(sequence.startIndex, offsetBy: start)
        let endIndex = sequence.index(sequence.startIndex, offsetBy: end)
        return String(sequence[startIndex..<endIndex])
    }
    
    // 현재 그룹을 중심으로 보이는 그룹 번호들 계산
    private var visibleGroupNumbers: [Int] {
        let currentGroup = sceneManager.currentGroup
        let totalGroups = sceneManager.totalGroups
        let maxVisible = 15 // 화면에 보이는 최대 그룹 수 (홀수로 설정)
        let halfVisible = maxVisible / 2
        
        // 현재 그룹을 중심으로 시작/끝 그룹 계산
        let startGroup = max(1, currentGroup - halfVisible)
        let endGroup = min(totalGroups, currentGroup + halfVisible)
        
        // 전체 그룹 수가 maxVisible보다 작은 경우만 1부터 시작
        let adjustedStartGroup: Int
        let adjustedEndGroup: Int
        
        if totalGroups <= maxVisible {
            // 전체 그룹 수가 적으면 모든 그룹을 표시
            adjustedStartGroup = 1
            adjustedEndGroup = totalGroups
        } else {
            // 전체 그룹 수가 많으면 현재 그룹을 중심으로 표시
            adjustedStartGroup = startGroup
            adjustedEndGroup = endGroup
        }
        
        let visibleGroups = Array(adjustedStartGroup...adjustedEndGroup)
        
        // 디버깅을 위한 로그
        print("🔍 visibleGroupNumbers: currentGroup=\(currentGroup), totalGroups=\(totalGroups)")
        print("🔍 visibleGroups: \(visibleGroups)")
        print("🔍 startGroup=\(adjustedStartGroup), endGroup=\(adjustedEndGroup)")
        
        return visibleGroups
    }
    
    var body: some View {
        let _ = print("🎨 SequenceBar rendering: currentGroup=\(sceneManager.currentGroup), groupSize=\(sceneManager.groupSize)")
        let _ = print("🎨 Display length: \(sceneManager.displayLength), actual display length: \(sceneManager.actualDisplayLength)")
        let _ = print("🎨 Sequence name: '\(sequence.prefix(20))...' (length: \(sequence.count))")
        let _ = print("🎨 Current group sequence length: \(currentGroupSequence.count)")
        let _ = print("🎨 Sequence start: \(sceneManager.displayStart), end: \(sceneManager.displayStart + sceneManager.actualDisplayLength)")
        
        return VStack(spacing: 4) {
            // Position indicator
            HStack {
                Text("Position: \(sceneManager.displayStart)")
                    .font(.caption2)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(sequence.count) bp")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            
            // Group navigation buttons (horizontal scroll with current group centered)
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(visibleGroupNumbers, id: \.self) { groupNumber in
                            GroupButton(
                                groupNumber: groupNumber,
                                isSelected: groupNumber == sceneManager.currentGroup,
                                onTap: { group in
                                    sceneManager.loadGroup(group)
                                }
                            )
                            .id("group_\(groupNumber)")
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 40)
                .onChange(of: sceneManager.currentGroup) { newGroup in
                    // Scroll to current group when it changes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("group_\(newGroup)", anchor: .center)
                        }
                    }
                }
                .onAppear {
                    // Scroll to current group on first appearance
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("group_\(sceneManager.currentGroup)", anchor: .center)
                        }
                    }
                }
            }
            
            // Current group sequence
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 2) {
                    ForEach(Array(currentGroupSequence.enumerated()), id: \.offset) { localIndex, base in
                        let globalIndex = sceneManager.displayStart + localIndex
                        
                        // Base cell
                        BaseCell(
                            base: base,
                            index: globalIndex,
                            isSelected: isSelected(globalIndex),
                            isInCurrentGroup: true  // All bases in current group are in current group
                        )
                        .onTapGesture {
                            print("👉 BaseCell tapped at global index: \(globalIndex), local index: \(localIndex), base: \(base)")
                            
                            // Toggle selection
                            if let range = selectedRange, range.contains(globalIndex) {
                                // Already selected - deselect
                                print("🔓 Deselecting base at index: \(globalIndex)")
                                selectedRange = nil
                                sceneManager.selectedBaseIndex = nil
                                sceneManager.clearHighlights()
                            } else {
                                // Select new base
                                print("🔒 Selecting base at index: \(globalIndex)")
                                
                                // Same group - select immediately
                                selectedRange = globalIndex..<(globalIndex + 1)
                                sceneManager.selectBase(at: globalIndex)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.7))
    }
    
    private func isSelected(_ index: Int) -> Bool {
        guard let range = selectedRange else { return false }
        return range.contains(index)
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
        let colorSettings = ColorSettings.shared
        switch base {
        case "A": return colorSettings.adenineColor
        case "T": return colorSettings.thymineColor
        case "G": return colorSettings.guanineColor
        case "C": return colorSettings.cytosineColor
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

