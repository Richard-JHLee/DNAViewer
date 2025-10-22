import SwiftUI

// MARK: - Helpers
fileprivate func complement(_ b: Character) -> Character {
    switch b {
    case "A": return "T"
    case "T": return "A"
    case "G": return "C"
    case "C": return "G"
    default:  return "N"
    }
}

fileprivate func baseColor(_ b: Character) -> Color {
    switch b {
    case "A": return .red
    case "T": return .blue
    case "G": return .green
    case "C": return .yellow
    default:  return .gray
    }
}

struct DNALadderView: View {
    @EnvironmentObject var sceneManager: DNASceneManager
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var drag: CGSize = .zero
    
    var sequence: DNASequence
    
    var body: some View {
        GeometryReader { geometry in
            ladderContent(geometry: geometry)
        }
        .background(Color.white)
    }
    
    private func ladderContent(geometry: GeometryProxy) -> some View {
        let W = geometry.size.width
        let H = geometry.size.height
        let margin: CGFloat = 16
        let xCenter = W / 2
        let xAmp = W * 0.33
        let yTop = margin
        let yBottom = H - margin
        let height = yBottom - yTop
        
        return Canvas { ctx, size in
            let N = currentGroupPairs.count  // 현재 그룹의 총 염기쌍 수
            let K = 4  // 교차(만남) 지점 수
            let omega = CGFloat(K + 1) * .pi / height
            
            func xLeft(_ y: CGFloat)  -> CGFloat { xCenter - xAmp * sin(omega * (y - yTop)) }
            func xRight(_ y: CGFloat) -> CGFloat { xCenter + xAmp * sin(omega * (y - yTop)) }
            
            // 노드(만남 지점)
            let yNodes: [CGFloat] = (0...(K+1)).map { j in yTop + (CGFloat(j) / CGFloat(K + 1)) * height }
            
            // 가중치 분배 (끝 0.5, 가운데 1.0)
            var weights = [0.5] + Array(repeating: 1.0, count: max(0, K-1)) + [0.5]
            let sumW = weights.reduce(0, +)
            let ideals = weights.map { $0 / sumW * Double(N) }
            var counts = ideals.map { Int(floor($0)) }
            var R = N - counts.reduce(0, +)
            // 소수부 큰 순서로 +1
            let order = ideals.enumerated().sorted { ($0.element - floor($0.element)) > ($1.element - floor($1.element)) }.map { $0.offset }
            var t = 0
            while R > 0 { counts[order[t % counts.count]] += 1; R -= 1; t += 1 }
            
            // 디버깅: 분배 결과 출력
            print("🧬 Group \(sceneManager.currentGroup): N=\(N) base pairs")
            print("📊 Weights: \(weights)")
            print("🎯 Ideals: \(ideals)")
            print("📈 Final counts: \(counts)")
            print("✅ Total: \(counts.reduce(0, +))")
            
            // 백본 곡선
            func strandPath(isLeft: Bool) -> Path {
                var p = Path()
                let steps = 800
                for s in 0...steps {
                    let y = yTop + CGFloat(s) / CGFloat(steps) * height
                    let x = isLeft ? xLeft(y) : xRight(y)
                    if s == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
                }
                return p
            }
            ctx.stroke(strandPath(isLeft: true),  with: .color(.orange), style: StrokeStyle(lineWidth: 3, lineJoin: .round))
            ctx.stroke(strandPath(isLeft: false), with: .color(.blue),   style: StrokeStyle(lineWidth: 3, lineJoin: .round))
            
            // 노드 점
            for y in yNodes {
                let nodeX = xLeft(y)
                let r: CGFloat = 3.2
                let rect = CGRect(x: nodeX - r, y: y - r, width: r*2, height: r*2)
                ctx.fill(Path(ellipseIn: rect), with: .color(.black))
            }
            
            // 구간 내부 염기쌍 균일 배치 (half-step)
            var globalIndex = 0
            for seg in 0..<(K+1) {
                let yStart = yNodes[seg]
                let yEnd   = yNodes[seg + 1]
                let n = counts[seg]
                guard n > 0 else { continue }
                let dy = (yEnd - yStart) / CGFloat(n)
                
                for k in 0..<n {
                    let y = yStart + (CGFloat(k) + 0.5) * dy
                    let xl = xLeft(y)
                    let xr = xRight(y)
                    
                    // 염기/상보
                    let p = currentGroupPairs[globalIndex]
                    let base = p.left
                    let comp = complement(base)
                    
                    // 염기쌍 막대
                    var rung = Path()
                    rung.move(to: CGPoint(x: xl, y: y))
                    rung.addLine(to: CGPoint(x: xr, y: y))
                    ctx.stroke(rung, with: .color(.primary), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    
                    // 염기 라벨
                    let leftLabel  = Text(String(base)).font(.caption).bold().foregroundColor(baseColor(base))
                    let rightLabel = Text(String(comp)).font(.caption).bold().foregroundColor(baseColor(comp))
                    ctx.draw(leftLabel,  at: CGPoint(x: xl - 10, y: y - 10))
                    ctx.draw(rightLabel, at: CGPoint(x: xr + 10, y: y - 10))
                    
                    globalIndex += 1
                }
            }
            
            // 프레임 가이드
            let frameRect = CGRect(x: margin, y: yTop, width: size.width - margin*2, height: height)
            ctx.stroke(Path(roundedRect: frameRect, cornerRadius: 10),
                       with: .color(.secondary.opacity(0.2)))
        }
        .scaleEffect(scale)
        .offset(x: offset.width + drag.width, y: offset.height + drag.height)
        .gesture(DragGesture().updating($drag) { v, st, _ in st = v.translation }
                    .onEnded { v in offset.width += v.translation.width; offset.height += v.translation.height })
    }
    
    // 현재 그룹의 염기쌍들
    private var currentGroupPairs: [BasePair] {
        let start = sceneManager.displayStart
        let length = sceneManager.displayLength
        
        var pairs: [BasePair] = []
        for i in 0..<length {
            let leftIndex = start + i
            let rightIndex = sequence.length - 1 - leftIndex
            
            if leftIndex < sequence.length && rightIndex >= 0 {
                let leftBase = sequence.sequence[sequence.sequence.index(sequence.sequence.startIndex, offsetBy: leftIndex)]
                let rightBase = sequence.sequence[sequence.sequence.index(sequence.sequence.startIndex, offsetBy: rightIndex)]
                pairs.append(BasePair(id: leftIndex, left: leftBase, right: rightBase))
            }
        }
        return pairs
    }
}

// MARK: - Legend
struct LegendView: View {
    @EnvironmentObject var sceneManager: DNASceneManager
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(["A", "T", "G", "C"], id: \.self) { base in
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(baseColor(Character(base)))
                        .frame(width: 12, height: 12)
                    Text(base)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    DNALadderView(sequence: DNASequence(name: "Test", sequence: "ATGCGTACGTATGCAGTCAG"))
        .environmentObject(DNASceneManager())
}