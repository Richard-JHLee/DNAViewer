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
        Canvas { ctx, size in
            // ===== 좌표/스케일 설정 =====
            let margin: CGFloat = 16
            let xCenter = W * 0.50
            let xAmp = W * 0.33
            let yTop = margin
            let yBottom = H - margin
            let height = yBottom - yTop
            
           let totalPairs = currentGroupPairs.count  // 현재 그룹의 총 염기쌍 수
           let leftCount = totalPairs / 2  // 왼쪽 가닥 염기 수
           let rightCount = totalPairs - leftCount  // 오른쪽 가닥 염기 수
           let K = 4  // 교차(만남) 지점 수
           let omega = CGFloat(K + 1) * .pi / height
            
            func xLeft(_ y: CGFloat) -> CGFloat  { xCenter - xAmp * sin(omega * (y - yTop)) }
            func xRight(_ y: CGFloat) -> CGFloat { xCenter + xAmp * sin(omega * (y - yTop)) }
            
            // ===== 노드(만나는 지점) 계산 =====
            let yNodes: [CGFloat] = (0...(K+1)).map { j in
                yTop + (CGFloat(j) / CGFloat(K + 1)) * height
            }
            
           // ===== 왼쪽 가닥 구간별 염기 개수 분배 (끝단 0.5 가중치) =====
           let weights = [0.5] + Array(repeating: 1.0, count: max(0, K-1)) + [0.5]
           let sumW = weights.reduce(0, +)  // W = K
           let leftIdeals = weights.map { $0 / sumW * Double(leftCount) }  // 왼쪽 가닥 분배
           var leftCounts = leftIdeals.map { Int(floor($0)) }
           var leftR = leftCount - leftCounts.reduce(0, +)
           
           // 왼쪽 가닥 잔여 염기 배정
           let leftOrder = leftIdeals.enumerated()
               .sorted { ($0.element - floor($0.element)) > ($1.element - floor($1.element)) }
               .map { $0.offset }
           var leftIdx = 0
           while leftR > 0 {
               leftCounts[leftOrder[leftIdx % leftCounts.count]] += 1
               leftR -= 1
               leftIdx += 1
           }
           
           // ===== 오른쪽 가닥 구간별 염기 개수 분배 (끝단 0.5 가중치) =====
           let rightIdeals = weights.map { $0 / sumW * Double(rightCount) }  // 오른쪽 가닥 분배
           var rightCounts = rightIdeals.map { Int(floor($0)) }
           var rightR = rightCount - rightCounts.reduce(0, +)
           
           // 오른쪽 가닥 잔여 염기 배정
           let rightOrder = rightIdeals.enumerated()
               .sorted { ($0.element - floor($0.element)) > ($1.element - floor($1.element)) }
               .map { $0.offset }
           var rightIdx = 0
           while rightR > 0 {
               rightCounts[rightOrder[rightIdx % rightCounts.count]] += 1
               rightR -= 1
               rightIdx += 1
           }
           
           // 디버깅: 분배 결과 출력
           print("🧬 Group \(sceneManager.currentGroup): Left=\(leftCount), Right=\(rightCount) bases")
           print("📊 Left counts: \(leftCounts) (total: \(leftCounts.reduce(0, +)))")
           print("📊 Right counts: \(rightCounts) (total: \(rightCounts.reduce(0, +)))")
            
            // ===== 백본(가닥) 곡선 그리기 =====
            func strandPath(isLeft: Bool) -> Path {
                var p = Path()
                let steps = 800
                for t in 0...steps {
                    let y = yTop + CGFloat(t) / CGFloat(steps) * height
                    let x = isLeft ? xLeft(y) : xRight(y)
                    if t == 0 { p.move(to: CGPoint(x: x, y: y)) }
                    else { p.addLine(to: CGPoint(x: x, y: y)) }
                }
                return p
            }
            
            let backboneColor = Color(red: 0.64, green: 0.59, blue: 0.93)
            ctx.stroke(strandPath(isLeft: true), with: .color(backboneColor), 
                      style: StrokeStyle(lineWidth: 3, lineJoin: .round))
            ctx.stroke(strandPath(isLeft: false), with: .color(backboneColor), 
                      style: StrokeStyle(lineWidth: 3, lineJoin: .round))
            
            // ===== 노드 표시 =====
            for y in yNodes {
                let nodeX = xLeft(y)
                let r: CGFloat = 3.5
                let rect = CGRect(x: nodeX - r, y: y - r, width: r*2, height: r*2)
                ctx.fill(Path(ellipseIn: rect), with: .color(.black))
            }
            
           // ===== 각 구간 내부에 염기쌍 균일 배치 (half-step 오프셋) =====
           var leftIndex = 0
           var rightIndex = 0
           
           for seg in 0..<(K+1) {
               let yStart = yNodes[seg]  // z_j
               let yEnd = yNodes[seg + 1]  // z_{j+1}
               let leftN = leftCounts[seg]  // 왼쪽 가닥 염기 수
               let rightN = rightCounts[seg]  // 오른쪽 가닥 염기 수
               
               // 왼쪽 가닥 염기 배치
               if leftN > 0 {
                   for k in 1...leftN {
                       guard leftIndex < leftCount else { break }
                       let p = currentGroupPairs[leftIndex]
                       
                       let y = yStart + (CGFloat(k) - 0.5) * (yEnd - yStart) / CGFloat(leftN)
                       let xl = xLeft(y)
                       let xr = xRight(y)
                       
                       // 염기쌍 색상 결정
                       let leftColor = Color(DNASceneManager.colorForBase(p.left, scheme: sceneManager.colorScheme, 
                                                                          position: p.id, totalLength: sequence.length))
                       let rightColor = Color(DNASceneManager.colorForBase(p.right, scheme: sceneManager.colorScheme, 
                                                                         position: p.id, totalLength: sequence.length))
                       
                       // 염기쌍 막대 그리기
                       let gap: CGFloat = 18
                       let barH: CGFloat = 8
                       let leftRect = CGRect(x: xl + 2, y: y - barH/2, 
                                             width: (xCenter - gap/2) - (xl + 2), height: barH)
                       let rightRect = CGRect(x: xCenter + gap/2, y: y - barH/2, 
                                             width: (xr - 2) - (xCenter + gap/2), height: barH)
                       
                       ctx.fill(Path(roundedRect: leftRect, cornerRadius: barH/2), with: .color(leftColor))
                       ctx.fill(Path(roundedRect: rightRect, cornerRadius: barH/2), with: .color(rightColor))
                       
                       // 수소 결합
                       let bondRect = CGRect(x: xCenter - gap/2, y: y - barH*0.15, width: gap, height: barH*0.3)
                       ctx.fill(Path(roundedRect: bondRect, cornerRadius: barH*0.15), with: .color(.white))
                       
                       // 염기 라벨
                       let fontSize: CGFloat = 10
                       let font = Font.system(size: fontSize, weight: .bold, design: .rounded)
                       ctx.draw(Text(String(p.left)).font(font).foregroundColor(.white), 
                               at: CGPoint(x: leftRect.midX, y: leftRect.midY))
                       ctx.draw(Text(String(p.right)).font(font).foregroundColor(.white), 
                               at: CGPoint(x: rightRect.midX, y: rightRect.midY))
                       
                       leftIndex += 1
                   }
               }
               
               // 오른쪽 가닥 염기 배치
               if rightN > 0 {
                   for k in 1...rightN {
                       guard rightIndex < rightCount else { break }
                       let p = currentGroupPairs[leftCount + rightIndex]
                       
                       let y = yStart + (CGFloat(k) - 0.5) * (yEnd - yStart) / CGFloat(rightN)
                       let xl = xLeft(y)
                       let xr = xRight(y)
                       
                       // 염기쌍 색상 결정
                       let leftColor = Color(DNASceneManager.colorForBase(p.left, scheme: sceneManager.colorScheme, 
                                                                          position: p.id, totalLength: sequence.length))
                       let rightColor = Color(DNASceneManager.colorForBase(p.right, scheme: sceneManager.colorScheme, 
                                                                         position: p.id, totalLength: sequence.length))
                       
                       // 염기쌍 막대 그리기
                       let gap: CGFloat = 18
                       let barH: CGFloat = 8
                       let leftRect = CGRect(x: xl + 2, y: y - barH/2, 
                                             width: (xCenter - gap/2) - (xl + 2), height: barH)
                       let rightRect = CGRect(x: xCenter + gap/2, y: y - barH/2, 
                                             width: (xr - 2) - (xCenter + gap/2), height: barH)
                       
                       ctx.fill(Path(roundedRect: leftRect, cornerRadius: barH/2), with: .color(leftColor))
                       ctx.fill(Path(roundedRect: rightRect, cornerRadius: barH/2), with: .color(rightColor))
                       
                       // 수소 결합
                       let bondRect = CGRect(x: xCenter - gap/2, y: y - barH*0.15, width: gap, height: barH*0.3)
                       ctx.fill(Path(roundedRect: bondRect, cornerRadius: barH*0.15), with: .color(.white))
                       
                       // 염기 라벨
                       let fontSize: CGFloat = 10
                       let font = Font.system(size: fontSize, weight: .bold, design: .rounded)
                       ctx.draw(Text(String(p.left)).font(font).foregroundColor(.white), 
                               at: CGPoint(x: leftRect.midX, y: leftRect.midY))
                       ctx.draw(Text(String(p.right)).font(font).foregroundColor(.white), 
                               at: CGPoint(x: rightRect.midX, y: rightRect.midY))
                       
                       rightIndex += 1
                   }
               }
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


