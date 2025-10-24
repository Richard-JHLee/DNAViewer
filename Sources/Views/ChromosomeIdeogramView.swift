//
//  ChromosomeIdeogramView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-22.
//

import SwiftUI

struct ChromosomeIdeogramView: View {
    let selectedGene: GeneModel?
    let neighboringGenes: [GeneModel]
    let onGeneSelected: (GeneModel) -> Void
    
    @State private var tapLocation: CGPoint?
    @State private var scale: CGFloat = 1.0
    @State private var showGeneInfo: Bool = false
    @State private var selectedGeneForInfo: GeneModel?
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 4) {
                // Zoom Controls
                zoomControls
                
                // Scrollable Chromosome View - responsive to device width
                ScrollView(.horizontal, showsIndicators: true) {
                    Canvas { context, size in
                        drawChromosome(context: context, size: size)
                        drawGeneMarkers(context: context, size: size)
                        drawEducationalElements(context: context, size: size)
                    }
                    .frame(width: max(geometry.size.width, geometry.size.width * scale), height: 180)
                    .contentShape(Rectangle())
                    .background(Color(.systemBackground))
                }
                .frame(height: 180)
                
                // Gene Info Display
                if showGeneInfo, let gene = selectedGeneForInfo {
                    geneInfoCard(for: gene)
                }
            }
        }
    }
    
    // MARK: - Zoom Controls
    private var zoomControls: some View {
        HStack {
            Text("Zoom: \(String(format: "%.1fx", scale))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: { scale = max(1.0, scale - 0.5) }) {
                Image(systemName: "minus.magnifyingglass")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .disabled(scale <= 1.0)
            
            Button(action: { scale = min(5.0, scale + 0.5) }) {
                Image(systemName: "plus.magnifyingglass")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .disabled(scale >= 5.0)
            
            Button(action: { scale = 1.0 }) {
                Text("Reset")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .disabled(scale == 1.0)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    // MARK: - Gene Info Card
    private func geneInfoCard(for gene: GeneModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(gene.display_name)
                    .font(.headline)
                    .foregroundColor(gene.isBRCA1 ? .red : .primary)
                
                Spacer()
                
                Button(action: { showGeneInfo = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                InfoRow(label: "ID", value: gene.id)
                InfoRow(label: "Chromosome", value: gene.chromosome)
                InfoRow(label: "Position", value: "\(gene.start) - \(gene.end)")
                InfoRow(label: "Length", value: "\(gene.length) bp")
                InfoRow(label: "Strand", value: gene.strand == 1 ? "+" : "-")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Drawing Methods
    private func drawChromosome(context: GraphicsContext, size: CGSize) {
        // Responsive sizing based on device width
        let margin: CGFloat = size.width * 0.05 // 5% margin
        let chromosomeWidth: CGFloat = size.width - margin * 2
        let chromosomeHeight: CGFloat = min(120, size.height * 0.5) // Max 120pt or 50% of height
        
        // Chromosome bounds - horizontal layout
        let chromosomeRect = CGRect(
            x: margin,
            y: (size.height - chromosomeHeight) / 2,
            width: chromosomeWidth,
            height: chromosomeHeight
        )
        
        // Draw chromosome outline with better styling
        var chromosomePath = Path()
        chromosomePath.addRoundedRect(in: chromosomeRect, cornerSize: CGSize(width: 12, height: 12))
        
        // Fill with gradient-like effect for better visual appeal
        context.fill(chromosomePath, with: .color(.orange.opacity(0.9)))
        
        // Draw chromosome border with shadow effect
        context.stroke(chromosomePath, with: .color(.orange), style: StrokeStyle(lineWidth: 3))
        
        // Draw chromosome label with better visibility
        let fontSize: CGFloat = max(14, size.width * 0.04) // Responsive font size
        let labelText = Text("Chr17")
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .foregroundColor(.white)
        context.draw(labelText, at: CGPoint(x: chromosomeRect.minX + 20, y: chromosomeRect.midY), anchor: .leading)
        
        // Draw centromere with better positioning
        let centromereX = chromosomeRect.minX + chromosomeRect.width * 0.35
        let centromereWidth: CGFloat = max(15, chromosomeWidth * 0.08)
        let centromereRect = CGRect(
            x: centromereX,
            y: chromosomeRect.minY + 15,
            width: centromereWidth,
            height: chromosomeRect.height - 30
        )
        var centromerePath = Path()
        centromerePath.addRoundedRect(in: centromereRect, cornerSize: CGSize(width: 6, height: 6))
        context.fill(centromerePath, with: .color(.gray.opacity(0.4)))
        context.stroke(centromerePath, with: .color(.gray), style: StrokeStyle(lineWidth: 1))
        
        // Draw chromosome bands for educational purposes
        drawChromosomeBands(context: context, rect: chromosomeRect)
    }
    
    private func drawChromosomeBands(context: GraphicsContext, rect: CGRect) {
        // Draw chromosome bands for educational purposes
        let bandCount = 6
        let bandHeight = rect.height / CGFloat(bandCount)
        
        for i in 0..<bandCount {
            let bandRect = CGRect(
                x: rect.minX + 5,
                y: rect.minY + CGFloat(i) * bandHeight,
                width: rect.width - 10,
                height: bandHeight - 2
            )
            
            // Alternate band colors for better visibility
            let opacity: Double = i % 2 == 0 ? 0.15 : 0.08
            context.fill(Path(bandRect), with: .color(.white.opacity(opacity)))
        }
    }
    
    private func drawEducationalElements(context: GraphicsContext, size: CGSize) {
        // Draw educational labels and annotations with better spacing
        
        // Add scale indicator - positioned at top right to avoid overlap
        let scaleText = Text("Scale: 1:1000 bp")
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(.secondary)
        context.draw(scaleText, at: CGPoint(x: size.width - 15, y: 25), anchor: .trailing)
        
        // Add chromosome information - positioned at top left to avoid overlap
        let infoText = Text("Chr17 • Human Genome")
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(.secondary)
        context.draw(infoText, at: CGPoint(x: 15, y: 25), anchor: .leading)
        
        // Draw coordinate system indicators with better spacing
        let margin: CGFloat = size.width * 0.05
        let chromosomeWidth: CGFloat = size.width - margin * 2
        let chromosomeHeight: CGFloat = min(120, size.height * 0.5)
        let chromosomeY = (size.height - chromosomeHeight) / 2
        
        // Position markers for educational purposes - positioned below chromosome with more space
        let positions: [CGFloat] = [0.1, 0.3, 0.5, 0.7, 0.9]
        let positionLabels = ["10kb", "30kb", "50kb", "70kb", "90kb"]
        
        for (index, position) in positions.enumerated() {
            let x = margin + chromosomeWidth * position
            let y = chromosomeY + chromosomeHeight + 5 // Tick marks right below chromosome box
            
            // Draw tick mark - longer and more visible
            var tickPath = Path()
            tickPath.move(to: CGPoint(x: x, y: y))
            tickPath.addLine(to: CGPoint(x: x, y: y + 8))
            context.stroke(tickPath, with: .color(.gray), style: StrokeStyle(lineWidth: 2))
            
            // Draw position label below tick mark
            let positionText = Text(positionLabels[index])
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.gray)
            context.draw(positionText, at: CGPoint(x: x, y: y + 18), anchor: .center)
        }
    }
    
    private func drawGeneMarkers(context: GraphicsContext, size: CGSize) {
        // Responsive sizing
        let margin: CGFloat = size.width * 0.05
        let chromosomeWidth: CGFloat = size.width - margin * 2
        let chromosomeHeight: CGFloat = min(120, size.height * 0.5)
        
        // Calculate chromosome bounds
        let chromosomeStart = margin
        let chromosomeEnd = chromosomeStart + chromosomeWidth
        let chromosomeY = (size.height - chromosomeHeight) / 2
        
        // Draw all genes
        for (index, gene) in neighboringGenes.enumerated() {
            let isSelected = gene.id == selectedGene?.id
            drawGeneMarker(
                context: context,
                gene: gene,
                index: index,
                chromosomeStart: chromosomeStart,
                chromosomeEnd: chromosomeEnd,
                chromosomeY: chromosomeY,
                chromosomeHeight: chromosomeHeight,
                isSelected: isSelected
            )
        }
    }
    
    private func drawGeneMarker(
        context: GraphicsContext,
        gene: GeneModel,
        index: Int,
        chromosomeStart: CGFloat,
        chromosomeEnd: CGFloat,
        chromosomeY: CGFloat,
        chromosomeHeight: CGFloat,
        isSelected: Bool
    ) {
        // Calculate position based on gene location
        let chromosomeWidth = chromosomeEnd - chromosomeStart
        let genePosition = CGFloat(gene.start) / 100000.0 // Scale down for demo
        let markerX = chromosomeStart + (genePosition * chromosomeWidth * 0.8)
        
        // Alternate above/below positioning for better visibility
        let isAbove = index % 2 == 0
        let markerY = isAbove ? chromosomeY - 40 : chromosomeY + chromosomeHeight + 40
        
        // Draw triangle marker with better styling
        var trianglePath = Path()
        trianglePath.move(to: CGPoint(x: markerX, y: markerY))
        trianglePath.addLine(to: CGPoint(x: markerX - 10, y: markerY + 15))
        trianglePath.addLine(to: CGPoint(x: markerX + 10, y: markerY + 15))
        trianglePath.closeSubpath()
        
        // Fill triangle with gene-specific color
        let markerColor: Color = isSelected ? .red : (gene.display_name == "BRCA1" ? .blue : .green)
        context.fill(trianglePath, with: .color(markerColor))
        context.stroke(trianglePath, with: .color(.white), style: StrokeStyle(lineWidth: 1))
        
        // Draw gene name label with better styling
        let fontSize: CGFloat = 11
        let labelText = Text(gene.display_name)
            .font(.system(size: fontSize, weight: .bold))
            .foregroundColor(.primary)
        
        let labelY = isAbove ? markerY - 30 : markerY + 25
        let labelWidth = CGFloat(gene.display_name.count * 8) + 10
        let labelRect = CGRect(x: markerX - labelWidth/2, y: labelY - 8, width: labelWidth, height: 16)
        
        // Draw background for label with better contrast
        var labelBackgroundPath = Path()
        labelBackgroundPath.addRoundedRect(in: labelRect, cornerSize: CGSize(width: 6, height: 6))
        context.fill(labelBackgroundPath, with: .color(.white.opacity(0.9)))
        context.stroke(labelBackgroundPath, with: .color(.gray), style: StrokeStyle(lineWidth: 1))
        
        context.draw(labelText, at: CGPoint(x: markerX, y: labelY), anchor: .center)
        
        // Draw connecting line to chromosome
        var linePath = Path()
        linePath.move(to: CGPoint(x: markerX, y: isAbove ? chromosomeY : chromosomeY + chromosomeHeight))
        linePath.addLine(to: CGPoint(x: markerX, y: markerY + (isAbove ? 15 : -15)))
        context.stroke(linePath, with: .color(markerColor.opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
    }
    
    // MARK: - Tap Handling
    private func handleTap(at location: CGPoint, size: CGSize) {
        guard let selectedGene = selectedGene else { return }
        
        let margin: CGFloat = 20
        let chromosomeWidth: CGFloat = 40
        let chromosomeHeight = size.height - margin * 2
        
        let chromosomeStart = (size.width - chromosomeWidth) / 2
        let chromosomeEnd = chromosomeStart + chromosomeWidth
        
        // Check if tap is near any gene marker
        for gene in neighboringGenes {
            let geneStart = CGFloat(gene.start)
            let geneEnd = CGFloat(gene.end)
            let selectedStart = CGFloat(selectedGene.start)
            let selectedEnd = CGFloat(selectedGene.end)
            
            let chromosomeLength = selectedEnd - selectedStart
            let geneMidpoint = (geneStart + geneEnd) / 2
            let normalizedPosition = (geneMidpoint - selectedStart) / chromosomeLength
            
            let yPosition = margin + normalizedPosition * chromosomeHeight
            
            let isLeftSide = gene.start < selectedGene.start
            let markerX = isLeftSide ? chromosomeStart - 30 : chromosomeEnd + 10
            
            // Check if tap is within marker bounds
            let markerRect = CGRect(
                x: markerX - 15,
                y: yPosition - 15,
                width: 30,
                height: 30
            )
            
            if markerRect.contains(location) {
                // Show gene info card with animation
                withAnimation {
                    selectedGeneForInfo = gene
                    showGeneInfo = true
                }
                
                // Also trigger the callback
                onGeneSelected(gene)
                break
            }
        }
    }
}

// MARK: - Helper Views
// InfoRow is already defined in InfoSheet.swift

// MARK: - CGSize Extension
extension CGSize {
    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        return CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
}

#Preview {
    ChromosomeIdeogramView(
        selectedGene: GeneModel(
            id: "ENSG00000012048",
            display_name: "BRCA1",
            seq_region_name: "17",
            start: 43044295,
            end: 43125483,
            strand: -1,
            description: "BRCA1 DNA repair associated [Source:HGNC Symbol;Acc:HGNC:1100]"
        ),
        neighboringGenes: [
            GeneModel(id: "ENSG00000012048", display_name: "BRCA1", seq_region_name: "17", start: 43044295, end: 43125483, strand: -1, description: nil),
            GeneModel(id: "ENSG00000141510", display_name: "TP53", seq_region_name: "17", start: 7668421, end: 7687490, strand: 1, description: nil)
        ],
        onGeneSelected: { _ in }
    )
    .frame(height: 300)
}
