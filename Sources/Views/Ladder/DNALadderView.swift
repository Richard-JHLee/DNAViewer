import SwiftUI

struct DNALadderView: View {
    let sequence: DNASequence
    @ObservedObject var sceneManager: DNASceneManager
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var drag: CGSize = .zero
    
    // 현재 그룹의 염기서열 쌍 계산
    private var currentGroupPairs: [BasePair] {
        let groupSize = sceneManager.groupSize
        let currentGroup = sceneManager.currentGroup
        let startIndex = (currentGroup - 1) * groupSize
        let endIndex = min(startIndex + groupSize, sequence.sequence.count)
        
        guard startIndex < sequence.sequence.count else { return [] }
        
        let subsequence = String(sequence.sequence.dropFirst(startIndex).prefix(endIndex - startIndex))
        return Array(subsequence.enumerated()).map { index, base in
            let complement: Character = {
                switch base {
                case "A": return "T"
                case "T": return "A"
                case "G": return "C"
                case "C": return "G"
                default: return "N"
                }
            }()
            return BasePair(id: startIndex + index, left: base, right: complement)
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H = geo.size.height
            
            // 데이터가 없으면 안내 메시지 표시
            if currentGroupPairs.isEmpty {
                VStack {
                    Spacer()
                    Text("No DNA sequence data available")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Please select a gene from the library")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            } else {
                ladderContent(width: W, height: H)
            }
        }
        .overlay(alignment: .bottomTrailing) { 
            if !currentGroupPairs.isEmpty {
                LegendView(colorScheme: sceneManager.colorScheme, sequenceLength: sequence.length).padding(8)
            }
        }
        .onAppear {
            print("🪜 DNALadderView appeared with \(currentGroupPairs.count) base pairs (Group \(sceneManager.currentGroup))")
        }
        .onChange(of: sceneManager.currentGroup) { newGroup in
            print("🪜 DNALadderView group changed to \(newGroup), now showing \(currentGroupPairs.count) base pairs")
        }
    }
    
    @ViewBuilder
    private func ladderContent(width W: CGFloat, height H: CGFloat) -> some View {
        let usableH = H * 0.9
        let spacing = max(usableH / CGFloat(max(currentGroupPairs.count, 1)), 10)
        let radius = min(W, H) * 0.18
        let backboneWidth: CGFloat = max(6, radius * 0.10)
        let centerX = W * 0.50  // 화면 중앙으로 이동
            
        Canvas { ctx, size in
            // 배경 그리기
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(.systemBackground)))
            
            let purple = Color(red: 0.64, green: 0.59, blue: 0.93)
            var left = Path(); var right = Path()
            let topY = (H - usableH) / 2
            let usable = usableH
            let turns = CGFloat.pi * 2.0 / 9.0
            
            // Backbone 경로 생성
            left.move(to: CGPoint(x: centerX - radius, y: topY))
            right.move(to: CGPoint(x: centerX + radius, y: topY))
            let steps = max(currentGroupPairs.count, 2)
            for i in 1...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let y = topY + t * usable
                let angle = t * turns * CGFloat(steps) * 0.18
                let lx = centerX - radius * cos(angle)
                let rx = centerX + radius * cos(angle)
                left.addLine(to: CGPoint(x: lx, y: y))
                right.addLine(to: CGPoint(x: rx, y: y))
            }
            ctx.stroke(left, with: .color(purple), lineWidth: backboneWidth)
            ctx.stroke(right, with: .color(purple), lineWidth: backboneWidth)
            
            // Base pairs 그리기
            for (i, p) in currentGroupPairs.enumerated() {
                let ty = topY + CGFloat(i) * spacing + spacing * 0.5
                let angle = CGFloat(i) * 0.20
                let lx = centerX - radius * cos(angle)
                let rx = centerX + radius * cos(angle)
                
                let gap: CGFloat = 18
                let barH: CGFloat = max(8, spacing * 0.35)
                let leftRect = CGRect(x: lx + backboneWidth * 0.5,
                                      y: ty - barH/2,
                                      width: (centerX - gap/2) - (lx + backboneWidth * 0.5),
                                      height: barH)
                let rightRect = CGRect(x: centerX + gap/2,
                                       y: ty - barH/2,
                                       width: (rx - backboneWidth * 0.5) - (centerX + gap/2),
                                       height: barH)
                
                // sceneManager의 colorScheme에 따라 색상 결정
                let globalIndex = p.id
                let leftColor = Color(DNASceneManager.colorForBase(p.left, scheme: sceneManager.colorScheme, position: globalIndex, totalLength: sequence.length))
                let rightColor = Color(DNASceneManager.colorForBase(p.right, scheme: sceneManager.colorScheme, position: globalIndex, totalLength: sequence.length))
                
                ctx.fill(Path(roundedRect: leftRect, cornerRadius: barH/2), with: .color(leftColor))
                ctx.fill(Path(roundedRect: rightRect, cornerRadius: barH/2), with: .color(rightColor))
                
                let bondRect = CGRect(x: centerX - gap/2, y: ty - barH*0.15, width: gap, height: barH*0.3)
                ctx.fill(Path(roundedRect: bondRect, cornerRadius: barH*0.15), with: .color(.white))
                
                let font = Font.system(size: barH * 0.7, weight: .bold, design: .rounded)
                ctx.draw(Text(String(p.left)).font(font).foregroundColor(.white), at: CGPoint(x: leftRect.midX, y: leftRect.midY))
                ctx.draw(Text(String(p.right)).font(font).foregroundColor(.white), at: CGPoint(x: rightRect.midX, y: rightRect.midY))
            }
        }
        .scaleEffect(scale)
        .offset(x: offset.width + drag.width, y: offset.height + drag.height)
        .gesture(DragGesture().updating($drag) { v, st, _ in st = v.translation }
                    .onEnded { v in offset.width += v.translation.width; offset.height += v.translation.height })
        .gesture(MagnificationGesture().onChanged { s in scale = max(0.5, min(3.0, s)) })
    }
}

struct LegendView: View {
    let colorScheme: DNAColorScheme
    let sequenceLength: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(["A","T","G","C"].enumerated()), id: \.offset) { index, b in
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(DNASceneManager.colorForBase(Character(b), 
                                                                  scheme: colorScheme, 
                                                                  position: index, 
                                                                  totalLength: sequenceLength)))
                        .frame(width: 16, height: 16)
                    Text(b).font(.caption).bold()
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
            }
        }
        .padding(6)
        .background(.thinMaterial)
        .cornerRadius(10)
    }
}


