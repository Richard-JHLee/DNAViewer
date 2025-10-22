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
    case "A": return Color(red: 0.8, green: 0.2, blue: 0.2) // 진한 빨강
    case "T": return Color(red: 0.2, green: 0.4, blue: 0.8) // 진한 파랑
    case "G": return Color(red: 0.2, green: 0.7, blue: 0.2) // 진한 초록
    case "C": return Color(red: 0.9, green: 0.8, blue: 0.1) // 진한 노랑
    default:  return .gray
    }
}

// MARK: - Interactive View
struct DNALadder2DInteractiveView: View {
    @State private var N: Int = 20 // 염기쌍 수
    @State private var K: Int = 4 // 교차(만남) 지점 수
    @State private var height: CGFloat = 600
    @State private var showLabels = true
    @State private var showBackbone = true
    @State private var showNodes = true
    @State private var mutations = Set<Int>() // 0...N-1 인덱스
    @State private var sequence: [Character] = Array("ATGCGTACGTATGCAGTCAG".prefix(20))
    
    var body: some View {
        VStack(spacing: 12) {
            // MARK: Canvas
            DNALadderCanvas(
                N: N, K: K, H: height, sequence: sequence, mutations: mutations,
                showLabels: showLabels, showBackbone: showBackbone, showNodes: showNodes
            )
            .frame(height: height + 32)
            .padding(.horizontal)
            
            // MARK: Controls
            VStack(spacing: 10) {
                HStack {
                    Label("Base Pairs", systemImage: "number")
                    Slider(value: Binding(get: { Double(N) }, set: { N = Int($0) }), in: 4...200, step: 1)
                    Text("\(N)")
                        .monospacedDigit()
                        .frame(width: 44, alignment: .trailing)
                }
                
                HStack {
                    Label("Crossings (K)", systemImage: "xmark.circle")
                    Slider(value: Binding(get: { Double(K) }, set: { K = max(1, Int($0)) }), in: 1...12, step: 1)
                    Text("\(K)")
                        .monospacedDigit()
                        .frame(width: 44, alignment: .trailing)
                }
                
                HStack {
                    Label("Height", systemImage: "arrow.up.arrow.down")
                    Slider(value: $height, in: 300...900, step: 10)
                    Text("\(Int(height)) px")
                        .monospacedDigit()
                        .frame(width: 80, alignment: .trailing)
                }
                
                HStack {
                    Toggle("Labels (A/T/G/C)", isOn: $showLabels)
                    Toggle("Backbone", isOn: $showBackbone)
                    Toggle("Nodes", isOn: $showNodes)
                }
                
                HStack {
                    Button {
                        // 랜덤 서열 생성
                        let alphabet: [Character] = ["A","T","G","C"]
                        sequence = (0..<max(N, 1)).map { _ in alphabet.randomElement()! }
                        // 기존 돌연변이는 유효 인덱스만 유지
                        mutations = Set(mutations.filter { $0 < N })
                    } label: {
                        Label("랜덤 서열", systemImage: "dice")
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        // 돌연변이 토글: N/5개 정도 무작위 마킹
                        var s = Set<Int>()
                        let m = max(1, N/5)
                        while s.count < m {
                            s.insert(Int.random(in: 0..<N))
                        }
                        mutations = s
                    } label: {
                        Label("돌연변이(임의)", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        mutations.removeAll()
                    } label: {
                        Label("돌연변이 지움", systemImage: "eraser")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)
        }
        .onChange(of: N) { _ in
            // N 변경 시 시퀀스 길이 보정
            let alphabet: [Character] = ["A","T","G","C"]
            if sequence.count < N {
                sequence.append(contentsOf: (sequence.count..<N).map { _ in alphabet.randomElement()! })
            } else if sequence.count > N {
                sequence = Array(sequence.prefix(N))
            }
            mutations = Set(mutations.filter { $0 < N })
        }
        .navigationTitle("DNA Ladder 2D (K-세그먼트 균등)")
    }
}

// MARK: - Canvas Renderer
struct DNALadderCanvas: View {
    var N: Int
    var K: Int
    var H: CGFloat
    var sequence: [Character]
    var mutations: Set<Int>
    var showLabels: Bool
    var showBackbone: Bool
    var showNodes: Bool
    
    var body: some View {
        Canvas { ctx, size in
            let margin: CGFloat = 16
            let height = H
            let xCenter = size.width / 2
            let xAmp = (size.width - margin*2) * 0.33
            let yTop = margin
            let omega = CGFloat(K + 1) * .pi / height
            
            // 위상 π 차의 사인 곡선 함수들
            func xLeft(_ y: CGFloat) -> CGFloat {
                xCenter - xAmp * sin(omega * (y - yTop))
            }
            func xRight(_ y: CGFloat) -> CGFloat {
                xCenter + xAmp * sin(omega * (y - yTop))
            }
            
            // 노드(만남 지점) - K개 교차점
            let yNodes: [CGFloat] = (0...(K+1)).map { j in
                yTop + (CGFloat(j) / CGFloat(K + 1)) * height
            }
            
            // 가중치 분배 (끝 0.5, 가운데 1.0)
            let weights = [0.5] + Array(repeating: 1.0, count: max(0, K-1)) + [0.5]
            let sumW = weights.reduce(0, +)
            let ideals = weights.map { $0 / sumW * Double(N) }
            var counts = ideals.map { Int(floor($0)) }
            var R = N - counts.reduce(0, +)
            
            // 소수부 큰 순서로 +1
            let order = ideals.enumerated().sorted { 
                ($0.element - floor($0.element)) > ($1.element - floor($1.element)) 
            }.map { $0.offset }
            var t = 0
            while R > 0 { 
                counts[order[t % counts.count]] += 1
                R -= 1
                t += 1 
            }
            
            // 백본 곡선
            if showBackbone {
                func strandPath(isLeft: Bool) -> Path {
                    var p = Path()
                    let steps = 800
                    for s in 0...steps {
                        let y = yTop + CGFloat(s) / CGFloat(steps) * height
                        let x = isLeft ? xLeft(y) : xRight(y)
                        if s == 0 { 
                            p.move(to: CGPoint(x: x, y: y)) 
                        } else { 
                            p.addLine(to: CGPoint(x: x, y: y)) 
                        }
                    }
                    return p
                }
                ctx.stroke(strandPath(isLeft: true), with: .color(.orange), 
                          style: StrokeStyle(lineWidth: 3, lineJoin: .round))
                ctx.stroke(strandPath(isLeft: false), with: .color(.blue), 
                          style: StrokeStyle(lineWidth: 3, lineJoin: .round))
            }
            
            // 노드 점
            if showNodes {
                for y in yNodes {
                    let nodeX = xLeft(y)
                    let r: CGFloat = 3.2
                    let rect = CGRect(x: nodeX - r, y: y - r, width: r*2, height: r*2)
                    ctx.fill(Path(ellipseIn: rect), with: .color(.black))
                }
            }
            
            // 구간 내부 염기쌍 균일 배치 (half-step)
            var globalIndex = 0
            for seg in 0..<(K+1) {
                let yStart = yNodes[seg]
                let yEnd = yNodes[seg + 1]
                let n = counts[seg]
                guard n > 0 else { continue }
                let dy = (yEnd - yStart) / CGFloat(n)
                
                for k in 0..<n {
                    let y = yStart + (CGFloat(k) + 0.5) * dy
                    let xl = xLeft(y)
                    let xr = xRight(y)
                    
                    // 염기/상보
                    let base = (globalIndex < sequence.count) ? sequence[globalIndex] : "N"
                    let comp = complement(base)
                    
                    // 돌연변이 하이라이트(배경 오라)
                    if mutations.contains(globalIndex) {
                        let mid = (xl + xr) / 2
                        let aura = Path(roundedRect: CGRect(x: mid - 30, y: y - 10, width: 60, height: 20), cornerRadius: 8)
                        ctx.fill(aura, with: .color(.pink.opacity(0.25)))
                    }
                    
                    // 염기쌍 막대
                    var rung = Path()
                    rung.move(to: CGPoint(x: xl, y: y))
                    rung.addLine(to: CGPoint(x: xr, y: y))
                    ctx.stroke(rung, with: .color(.primary), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    
                    // 염기 라벨
                    if showLabels {
                        let leftLabel = Text(String(base)).font(.caption).bold().foregroundColor(baseColor(base))
                        let rightLabel = Text(String(comp)).font(.caption).bold().foregroundColor(baseColor(comp))
                        ctx.draw(leftLabel, at: CGPoint(x: xl - 10, y: y - 10))
                        ctx.draw(rightLabel, at: CGPoint(x: xr + 10, y: y - 10))
                    }
                    
                    globalIndex += 1
                }
            }
            
            // 프레임 가이드
            let frameRect = CGRect(x: margin, y: yTop, width: size.width - margin*2, height: height)
            ctx.stroke(Path(roundedRect: frameRect, cornerRadius: 10), 
                      with: .color(.secondary.opacity(0.2)))
        }
    }
}

// MARK: - Legacy View (기존 호환성 유지)
struct DNALadderView: View {
    @EnvironmentObject var sceneManager: DNASceneManager
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var drag: CGSize = .zero
    
    let sequence: DNASequence
    
    var body: some View {
        GeometryReader { geometry in
            ladderContent(geometry: geometry)
        }
        .background(Color(red: 0.98, green: 0.98, blue: 1.0))
        .scaleEffect(scale)
        .offset(offset)
        .offset(drag)
        .gesture(DragGesture().updating($drag) { v, st, _ in st = v.translation }
                    .onEnded { v in offset.width += v.translation.width; offset.height += v.translation.height })
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
            self.drawLadder(ctx: ctx, size: size, xCenter: xCenter, xAmp: xAmp, yTop: yTop, height: height)
        }
    }
    
    private func drawLadder(ctx: GraphicsContext, size: CGSize, xCenter: CGFloat, xAmp: CGFloat, yTop: CGFloat, height: CGFloat) {
            let N = currentGroupPairs.count  // 현재 그룹의 총 염기쌍 수
            print("🎯 Canvas Debug - N (base pairs): \(N)")
            let K = 4  // 교차(만남) 지점 수
            // 위아래 끝부분에서 만나지 않도록 범위 조정
            let extendedHeight = height * 1.2 // 20% 확장된 높이
            let yOffset = (extendedHeight - height) / 2 // 중앙 정렬을 위한 오프셋
            let omega = CGFloat(K + 1) * .pi / extendedHeight
            
            func xLeft(_ y: CGFloat)  -> CGFloat { 
                let normalizedY = y - yTop + yOffset
                return xCenter - xAmp * sin(omega * normalizedY) 
            }
            func xRight(_ y: CGFloat) -> CGFloat { 
                let normalizedY = y - yTop + yOffset
                return xCenter + xAmp * sin(omega * normalizedY) 
            }
            
            // 노드(만남 지점)
            let yNodes: [CGFloat] = (0...(K+1)).map { j in yTop + (CGFloat(j) / CGFloat(K + 1)) * height }
            
            // 가중치 분배 (끝 0.5, 가운데 1.0)
            let weights = [0.5] + Array(repeating: 1.0, count: max(0, K-1)) + [0.5]
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
            // 보라색 백본 (rgb: 0.64, 0.59, 0.93)
            let backboneColor = Color(red: 0.64, green: 0.59, blue: 0.93)
            ctx.stroke(strandPath(isLeft: true),  with: .color(backboneColor), style: StrokeStyle(lineWidth: 3, lineJoin: .round))
            ctx.stroke(strandPath(isLeft: false), with: .color(backboneColor), style: StrokeStyle(lineWidth: 3, lineJoin: .round))
            
            // 노드 점 (검은색 원형, 3.5pt)
            for y in yNodes {
                let nodeX = xLeft(y)
                let r: CGFloat = 3.5
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
                    
                    // 중심점 계산
                    let xCenter = (xl + xr) / 2
                    
                    // 왼쪽 염기 막대 (염기 색깔)
                    var leftBar = Path()
                    leftBar.move(to: CGPoint(x: xl, y: y))
                    leftBar.addLine(to: CGPoint(x: xCenter - 5, y: y))
                    ctx.stroke(leftBar, with: .color(baseColor(base)), 
                              style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    
                    // 오른쪽 염기 막대 (상보 염기 색깔)
                    var rightBar = Path()
                    rightBar.move(to: CGPoint(x: xCenter + 5, y: y))
                    rightBar.addLine(to: CGPoint(x: xr, y: y))
                    ctx.stroke(rightBar, with: .color(baseColor(comp)), 
                              style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    
                    // 가운데 수소 결합 (흰색 점선)
                    var hydrogenBond = Path()
                    hydrogenBond.move(to: CGPoint(x: xCenter - 5, y: y))
                    hydrogenBond.addLine(to: CGPoint(x: xCenter + 5, y: y))
                    ctx.stroke(hydrogenBond, with: .color(.white), 
                              style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 2]))
                    
                    // Restriction enzyme cut site 하이라이트
                    let absolutePosition = p.id  // BasePair의 id가 절대 위치
                    let isCutSite = sceneManager.highlightedCutSites.contains(absolutePosition)
                    
                    if isCutSite {
                        // 배경 원형
                        let circleRadius: CGFloat = 20
                        let circleRect = CGRect(
                            x: xCenter - circleRadius,
                            y: y - circleRadius,
                            width: circleRadius * 2,
                            height: circleRadius * 2
                        )
                        ctx.fill(Path(ellipseIn: circleRect), with: .color(.red.opacity(0.3)))

                        // 가위 텍스트 심볼 (GraphicsContext가 지원하는 Text 사용)
                        let scissorText = Text("✂︎").font(.system(size: 16, weight: .bold)).foregroundColor(.red)
                        ctx.draw(scissorText, at: CGPoint(x: xCenter, y: y - 25))
                    }
                    
                    // 염기 라벨 (막대 위쪽에 배치)
                    let leftLabel  = Text(String(base)).font(.system(size: 10, weight: .bold)).foregroundColor(baseColor(base))
                    let rightLabel = Text(String(comp)).font(.system(size: 10, weight: .bold)).foregroundColor(baseColor(comp))
                    ctx.draw(leftLabel,  at: CGPoint(x: xl - 12, y: y - 12))
                    ctx.draw(rightLabel, at: CGPoint(x: xr + 12, y: y - 12))
                    
                    globalIndex += 1
                }
            }
            
            // 프레임 가이드
            let margin: CGFloat = 16
            let frameRect = CGRect(x: margin, y: yTop, width: size.width - margin*2, height: height)
            ctx.stroke(Path(roundedRect: frameRect, cornerRadius: 10),
                      with: .color(.secondary.opacity(0.2)))
    }
    
    // 현재 그룹의 염기쌍들
    private var currentGroupPairs: [BasePair] {
        var pairs: [BasePair] = []
        let sequenceString = sequence.sequence
        
        // 그룹별 시작 위치 계산 (sceneManager의 groupSize 사용)
        let groupSize = sceneManager.groupSize
        let startIndex = (sceneManager.currentGroup - 1) * groupSize
        let endIndex = min(startIndex + groupSize, sequenceString.count)
        
        // 현재 그룹의 염기만 가져오기
        for i in startIndex..<endIndex {
            if i < sequenceString.count {
                let index = sequenceString.index(sequenceString.startIndex, offsetBy: i)
                let base = sequenceString[index]
                let complementBase = complement(base)
                pairs.append(BasePair(id: i, left: base, right: complementBase))
            } else {
                // 시퀀스가 부족하면 기본 염기 사용
                pairs.append(BasePair(id: i, left: "A", right: "T"))
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
                    Circle()
                        .fill(baseColor(Character(base)))
                        .frame(width: 12, height: 12)
                    Text(base)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

#Preview {
    DNALadder2DInteractiveView()
        .padding(.vertical)
        .background(Color(.systemBackground))
}