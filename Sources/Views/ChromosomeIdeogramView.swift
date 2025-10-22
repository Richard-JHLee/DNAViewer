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
    
    var body: some View {
        Canvas { context, size in
            drawChromosome(context: context, size: size)
            drawGeneMarkers(context: context, size: size)
        }
        .onTapGesture { location in
            handleTap(at: location, in: size)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Drawing Methods
    private func drawChromosome(context: GraphicsContext, size: CGSize) {
        guard let gene = selectedGene else { return }
        
        let margin: CGFloat = 20
        let chromosomeWidth: CGFloat = 40
        let chromosomeHeight = size.height - margin * 2
        
        // Chromosome bounds
        let chromosomeRect = CGRect(
            x: (size.width - chromosomeWidth) / 2,
            y: margin,
            width: chromosomeWidth,
            height: chromosomeHeight
        )
        
        // Draw chromosome outline
        var chromosomePath = Path()
        chromosomePath.addRoundedRect(in: chromosomeRect, cornerSize: CGSize(width: 8, height: 8))
        
        // Fill with light gray
        context.fill(chromosomePath, with: .color(.gray.opacity(0.3)))
        
        // Draw chromosome border
        context.stroke(chromosomePath, with: .color(.gray), style: StrokeStyle(lineWidth: 2))
        
        // Draw centromere (middle band)
        let centromereRect = CGRect(
            x: chromosomeRect.minX + 5,
            y: chromosomeRect.midY - 8,
            width: chromosomeRect.width - 10,
            height: 16
        )
        var centromerePath = Path()
        centromerePath.addRoundedRect(in: centromereRect, cornerSize: CGSize(width: 4, height: 4))
        context.fill(centromerePath, with: .color(.gray.opacity(0.6)))
        
        // Draw chromosome bands (simplified)
        drawChromosomeBands(context: context, rect: chromosomeRect)
    }
    
    private func drawChromosomeBands(context: GraphicsContext, rect: CGRect) {
        let bandCount = 8
        let bandHeight = rect.height / CGFloat(bandCount)
        
        for i in 0..<bandCount {
            let bandRect = CGRect(
                x: rect.minX + 2,
                y: rect.minY + CGFloat(i) * bandHeight,
                width: rect.width - 4,
                height: bandHeight - 1
            )
            
            let opacity: Double = i % 2 == 0 ? 0.1 : 0.05
            context.fill(Path(rect: bandRect), with: .color(.gray.opacity(opacity)))
        }
    }
    
    private func drawGeneMarkers(context: GraphicsContext, size: CGSize) {
        guard let selectedGene = selectedGene else { return }
        
        let margin: CGFloat = 20
        let chromosomeWidth: CGFloat = 40
        let chromosomeHeight = size.height - margin * 2
        
        // Calculate chromosome bounds
        let chromosomeStart = (size.width - chromosomeWidth) / 2
        let chromosomeEnd = chromosomeStart + chromosomeWidth
        
        // Draw all genes
        for gene in neighboringGenes {
            let isSelected = gene.id == selectedGene.id
            drawGeneMarker(
                context: context,
                gene: gene,
                selectedGene: selectedGene,
                chromosomeStart: chromosomeStart,
                chromosomeEnd: chromosomeEnd,
                chromosomeHeight: chromosomeHeight,
                margin: margin,
                isSelected: isSelected
            )
        }
    }
    
    private func drawGeneMarker(
        context: GraphicsContext,
        gene: GeneModel,
        selectedGene: GeneModel,
        chromosomeStart: CGFloat,
        chromosomeEnd: CGFloat,
        chromosomeHeight: CGFloat,
        margin: CGFloat,
        isSelected: Bool
    ) {
        // Calculate position based on gene coordinates
        let geneStart = CGFloat(gene.start)
        let geneEnd = CGFloat(gene.end)
        let selectedStart = CGFloat(selectedGene.start)
        let selectedEnd = CGFloat(selectedGene.end)
        
        // Normalize position within chromosome
        let chromosomeLength = selectedEnd - selectedStart
        let geneMidpoint = (geneStart + geneEnd) / 2
        let normalizedPosition = (geneMidpoint - selectedStart) / chromosomeLength
        
        // Calculate Y position
        let yPosition = margin + normalizedPosition * chromosomeHeight
        
        // Determine marker position (left or right of chromosome)
        let isLeftSide = gene.start < selectedGene.start
        let markerX = isLeftSide ? chromosomeStart - 30 : chromosomeEnd + 10
        
        // Draw marker
        let markerColor: Color = isSelected ? .red : (gene.isBRCA1 ? .blue : .green)
        let markerSize: CGFloat = isSelected ? 12 : 8
        
        let markerRect = CGRect(
            x: markerX - markerSize/2,
            y: yPosition - markerSize/2,
            width: markerSize,
            height: markerSize
        )
        
        context.fill(Path(ellipseIn: markerRect), with: .color(markerColor))
        
        // Draw marker border
        context.stroke(Path(ellipseIn: markerRect), with: .color(.white), style: StrokeStyle(lineWidth: 1))
        
        // Draw gene name label
        let labelFont = Font.system(size: 10, weight: .bold)
        let labelText = Text(gene.display_name)
            .font(labelFont)
            .foregroundColor(markerColor)
        
        let labelX = isLeftSide ? markerX - 50 : markerX + 15
        context.draw(labelText, at: CGPoint(x: labelX, y: yPosition), anchor: .center)
        
        // Draw connecting line
        let lineStartX = isLeftSide ? chromosomeStart : chromosomeEnd
        let lineEndX = markerX
        
        var linePath = Path()
        linePath.move(to: CGPoint(x: lineStartX, y: yPosition))
        linePath.addLine(to: CGPoint(x: lineEndX, y: yPosition))
        
        context.stroke(linePath, with: .color(markerColor.opacity(0.5)), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
    }
    
    // MARK: - Tap Handling
    private func handleTap(at location: CGPoint, in size: CGSize) {
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
                onGeneSelected(gene)
                break
            }
        }
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
            strand: -1
        ),
        neighboringGenes: [
            GeneModel(id: "ENSG00000012048", display_name: "BRCA1", seq_region_name: "17", start: 43044295, end: 43125483, strand: -1),
            GeneModel(id: "ENSG00000141510", display_name: "TP53", seq_region_name: "17", start: 7668421, end: 7687490, strand: 1)
        ],
        onGeneSelected: { _ in }
    )
    .frame(height: 200)
}
