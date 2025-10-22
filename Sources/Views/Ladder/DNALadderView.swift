import SwiftUI

struct DNALadderView: View {
    let pairs: [BasePair]
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var drag: CGSize = .zero
    
    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H = geo.size.height
            let usableH = H * 0.9
            let spacing = max(usableH / CGFloat(max(pairs.count, 1)), 10)
            let radius = min(W, H) * 0.18
            let backboneWidth: CGFloat = max(6, radius * 0.10)
            let centerX = W * 0.30
            
            Canvas { ctx, size in
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(.systemBackground)))
                
                let purple = Color(red: 0.64, green: 0.59, blue: 0.93)
                var left = Path(); var right = Path()
                let topY = (H - usableH) / 2
                let usable = usableH
                let turns = CGFloat.pi * 2.0 / 9.0
                
                left.move(to: CGPoint(x: centerX - radius, y: topY))
                right.move(to: CGPoint(x: centerX + radius, y: topY))
                let steps = max(pairs.count, 2)
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
                
                for (i, p) in pairs.enumerated() {
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
                    ctx.fill(Path(roundedRect: leftRect, cornerRadius: barH/2), with: .color(ColorPalette.base(p.left)))
                    ctx.fill(Path(roundedRect: rightRect, cornerRadius: barH/2), with: .color(ColorPalette.base(p.right)))
                    
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
        .overlay(alignment: .bottomTrailing) { LegendView().padding(8) }
    }
}

struct LegendView: View {
    var body: some View {
        HStack(spacing: 8) {
            ForEach(["A","T","G","C"], id: \.self) { b in
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ColorPalette.base(Character(b)))
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


