import SwiftUI

struct GenomeMapView: View {
    let length: Int
    let genes: [GeneMark]
    let title: String
    
    @State private var scale: CGFloat = 1.0
    @GestureState private var drag: CGSize = .zero
    @State private var offset: CGSize = .zero
    @State private var selected: GeneMark?
    
    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let barY = geo.size.height * 0.55
            let barW = max(W * 0.70, 300)
            let barH: CGFloat = 22
            let originX = (W - barW)/2 + offset.width + drag.width
            
            ZStack {
                Text(title).font(.title2).bold().position(x: originX - 60, y: barY - 32)
                
                RoundedRectangle(cornerRadius: barH/2)
                    .fill(ColorPalette.chromosome)
                    .frame(width: barW * scale, height: barH)
                    .overlay(
                        HStack(spacing: 0) {
                            ColorPalette.chromosomeDark
                            ColorPalette.chromosome
                            ColorPalette.chromosomeDark
                        }
                        .mask(RoundedRectangle(cornerRadius: barH/2).frame(width: barW * scale, height: barH))
                    )
                    .position(x: originX + (barW * scale)/2, y: barY)
                
                ForEach(genes) { g in
                    let startX = originX + (CGFloat(g.start) / CGFloat(max(length,1))) * (barW * scale)
                    let endX   = originX + (CGFloat(g.end) / CGFloat(max(length,1)))   * (barW * scale)
                    let w = max(endX - startX, 46)
                    let markerY = barY - 28
                    VStack(spacing: 4) {
                        Text(g.name)
                            .font(.caption).bold().foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 8).fill(g.color))
                        Triangle().fill(g.color).frame(width: 10, height: 6)
                    }
                    .position(x: startX + w/2, y: markerY)
                    .onTapGesture { selected = g }
                }
            }
            .gesture(DragGesture().updating($drag) { v, st, _ in st = v.translation }
                        .onEnded { v in offset.width += v.translation.width })
            .gesture(MagnificationGesture().onChanged { s in scale = max(0.5, min(3.0, s)) })
            .popover(item: $selected) { g in
                if #available(iOS 16.0, *) {
                    GenomeMarkerTooltip(gene: g)
                        .presentationDetents([.fraction(0.25)])
                } else {
                    GenomeMarkerTooltip(gene: g)
                }
            }
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

struct GenomeMarkerTooltip: View {
    let gene: GeneMark
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(gene.name).font(.headline)
            Text("Range: \(gene.start) – \(gene.end)")
                .font(.subheadline).foregroundColor(.secondary)
        }
        .padding()
    }
}


