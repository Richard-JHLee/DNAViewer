//
//  GeneStructureView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-23.
//

import SwiftUI

struct GeneStructureView: View {
    @ObservedObject var viewModel: GeneViewModel
    @ObservedObject var sceneManager: DNASceneManager
    let currentSequence: DNASequence?
    @State private var isExpanded: Bool = true
    @State private var isBlinking: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with expand/collapse button
            headerView
            
            // Expandable content
            if isExpanded {
                structureContent
                    .onAppear {
                        startBlinking()
                    }
            }
        }
    }
    
    // MARK: - Blinking Animation
    private func startBlinking() {
        withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            isBlinking = true
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded.toggle()
            }
        }) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("Gene Structure Visualization")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Structure Content
    private var structureContent: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 4) {
                if let gene = viewModel.selectedGene {
                    // Gene info
                    geneInfoBar(gene: gene)
                    
                    // Full gene structure diagram
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Full Gene Structure")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                        ScrollView(.horizontal, showsIndicators: true) {
                            structureDiagram
                                .padding(.horizontal, 4)
                        }
                        .frame(height: 40)
                    }
                    
                    Divider()
                        .padding(.horizontal, 4)
                    
                    // Detail view of current group
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Group Detail View")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                    detailDiagram
                        .frame(height: 200)
                    }
                    
                    // Legend
                    legendView
                } else {
                    Text("No gene selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding(.vertical, 4)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Gene Info Bar
    private func geneInfoBar(gene: GeneModel) -> some View {
        VStack(spacing: 4) {
            Text("\(gene.display_name) Gene Structure")
                .font(.caption)
                .fontWeight(.semibold)
            
            Text("Chr\(gene.chromosome): \(gene.start.formatted()) - \(gene.end.formatted()) • \(gene.length.formatted()) bp")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Structure Diagram
    private var structureDiagram: some View {
        Canvas { context, size in
            guard let gene = viewModel.selectedGene else { return }
            
            let geneLength = gene.end - gene.start + 1
            let geneScale = size.width / CGFloat(geneLength)  // For drawing exons based on gene coordinates
            let sequenceLength = currentSequence?.sequence.count ?? geneLength
            let positionScale = size.width / CGFloat(sequenceLength)  // For current position indicator
            let trackHeight: CGFloat = 120
            let trackY = size.height / 2 - trackHeight / 2
            
            // Draw full gene region including promoter and downstream
            // Promoter region (1kb upstream)
            let promoterLength: CGFloat = 1000
            let promoterStart: CGFloat = -promoterLength * geneScale
            if promoterStart > -size.width {
                let promoterRect = CGRect(x: max(promoterStart, 0), y: trackY + 15, width: min(promoterLength * geneScale, size.width), height: trackHeight - 30)
                context.fill(Path(roundedRect: promoterRect, cornerRadius: 3), with: .color(.pink.opacity(0.4)))
                
                if promoterLength * geneScale > 30 {
                    let promoterLabel = Text("Promoter")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.pink)
                    context.draw(promoterLabel, at: CGPoint(x: max(promoterStart, 0) + min(promoterLength * geneScale, size.width) / 2, y: trackY + trackHeight / 2), anchor: .center)
                }
            }
            
            // Downstream region (1kb downstream)
            let downstreamStart = size.width
            let downstreamLength: CGFloat = 1000
            let downstreamRect = CGRect(x: downstreamStart, y: trackY + 15, width: downstreamLength * geneScale, height: trackHeight - 30)
            context.fill(Path(roundedRect: downstreamRect, cornerRadius: 3), with: .color(.brown.opacity(0.4)))
            
            if downstreamLength * geneScale > 30 {
                let downstreamLabel = Text("Downstream")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.brown)
                context.draw(downstreamLabel, at: CGPoint(x: downstreamStart + downstreamLength * geneScale / 2, y: trackY + trackHeight / 2), anchor: .center)
            }
            
            // Draw baseline (intron line)
            var baselinePath = Path()
            baselinePath.move(to: CGPoint(x: max(promoterStart, 0), y: trackY + trackHeight / 2))
            baselinePath.addLine(to: CGPoint(x: downstreamStart + downstreamLength * geneScale, y: trackY + trackHeight / 2))
            context.stroke(baselinePath, with: .color(.orange.opacity(0.5)), lineWidth: 3)
            
            // Draw exons with appropriate colors
            for exon in viewModel.availableExons {
                let exonStart = CGFloat(exon.start - gene.start) * geneScale
                let exonWidth = CGFloat(exon.length) * geneScale
                
                // Determine color based on region type
                let color = getExonColor(exon)
                
                // Draw exon box
                let exonRect = CGRect(
                    x: exonStart,
                    y: trackY,
                    width: max(exonWidth, 3), // Minimum 3px width
                    height: trackHeight
                )
                
                context.fill(
                    Path(roundedRect: exonRect, cornerRadius: 4),
                    with: .color(color)
                )
                
                // Draw exon label - always show if width > 5px
                if exonWidth > 5 {
                    let labelText = Text("E\(exon.rank)")
                        .font(.system(size: exonWidth > 20 ? 11 : 8, weight: .bold))
                        .foregroundColor(.white)
                    
                    context.draw(
                        labelText,
                        at: CGPoint(x: exonStart + exonWidth / 2, y: trackY + trackHeight / 2),
                        anchor: .center
                    )
                }
            }
            
            // Draw current position indicator with blinking effect (use positionScale!)
            let currentStart = sceneManager.displayStart
            let currentEnd = currentStart + sceneManager.displayLength
            let currentPosStart = CGFloat(currentStart) * positionScale  // Use sequence-based scale!
            let currentPosWidth = CGFloat(sceneManager.displayLength) * positionScale
            
            // Debug logging
            print("🎯 ========== Gene Structure Position Debug ==========")
            print("🎯 Gene: \(gene.display_name)")
            print("🎯 Gene length (genomic): \(geneLength) bp")
            print("🎯 Gene start-end: \(gene.start) - \(gene.end)")
            print("🎯 Sequence length: \(sequenceLength) bp")
            if let seq = currentSequence?.sequence {
                print("🎯 Actual sequence length: \(seq.count) bp")
            }
            print("🎯 Current group: \(sceneManager.currentGroup) / \(sceneManager.totalGroups)")
            print("🎯 Display start: \(currentStart)")
            print("🎯 Display length: \(sceneManager.displayLength)")
            print("🎯 Display end: \(currentEnd)")
            print("🎯 Canvas size: \(size.width) x \(size.height)")
            print("🎯 Gene scale: \(geneScale) (for drawing exons)")
            print("🎯 Position scale: \(positionScale) (for current position)")
            print("🎯 Calculated position X: \(currentPosStart) px")
            print("🎯 Calculated width: \(currentPosWidth) px")
            print("🎯 Position %: \(Double(currentStart) / Double(sequenceLength) * 100)%")
            print("🎯 =============================================\n")
            
            // Blinking highlight box
            let highlightRect = CGRect(
                x: currentPosStart - 2,
                y: trackY - 5,
                width: max(currentPosWidth + 4, 6),
                height: trackHeight + 10
            )
            
            let opacity = isBlinking ? 0.3 : 0.7
            context.fill(
                Path(roundedRect: highlightRect, cornerRadius: 6),
                with: .color(.red.opacity(opacity))
            )
            
            // Border for current position
            context.stroke(
                Path(roundedRect: highlightRect, cornerRadius: 6),
                with: .color(.red),
                lineWidth: 2
            )
            
            // Arrow indicator
            let arrowY: CGFloat = 10
            var arrowPath = Path()
            arrowPath.move(to: CGPoint(x: currentPosStart + currentPosWidth / 2, y: arrowY))
            arrowPath.addLine(to: CGPoint(x: currentPosStart + currentPosWidth / 2 - 6, y: arrowY - 8))
            arrowPath.addLine(to: CGPoint(x: currentPosStart + currentPosWidth / 2 + 6, y: arrowY - 8))
            arrowPath.closeSubpath()
            context.fill(arrowPath, with: .color(.red))
            
            // "You are here" label with group info
            let groupInfo = "Group \(sceneManager.currentGroup)/\(sceneManager.totalGroups)"
            let labelText = Text("📍 \(groupInfo)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.red)
            context.draw(labelText, at: CGPoint(x: currentPosStart + currentPosWidth / 2, y: arrowY + 8), anchor: .top)
            
            // Current position bp range and percentage
            let percentage = String(format: "%.1f", Double(currentStart) / Double(sequenceLength) * 100)
            let rangeText = Text("\(currentStart)-\(currentEnd-1)bp (\(percentage)%)")
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(.red)
            context.draw(rangeText, at: CGPoint(x: currentPosStart + currentPosWidth / 2, y: size.height - 5), anchor: .bottom)
            
            // Draw scale markers and bp positions at bottom
            let markerY = trackY + trackHeight + 20
            let markerPositions = [0.0, 0.25, 0.5, 0.75, 1.0]
            
            for position in markerPositions {
                let x = size.width * position
                let genomicPos = Int(Double(geneLength) * position) + gene.start
                
                // Draw tick mark
                var tickPath = Path()
                tickPath.move(to: CGPoint(x: x, y: markerY))
                tickPath.addLine(to: CGPoint(x: x, y: markerY + 10))
                context.stroke(tickPath, with: .color(.gray), lineWidth: 2)
                
                // Draw bp position
                let posText = Text("\(formatBP(genomicPos))")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.gray)
                context.draw(posText, at: CGPoint(x: x, y: markerY + 14), anchor: .top)
            }
            
            // Draw intron regions between exons
            let sortedExons = viewModel.availableExons.sorted { $0.start < $1.start }
            for i in 0..<(sortedExons.count - 1) {
                let currentExon = sortedExons[i]
                let nextExon = sortedExons[i + 1]
                
                let intronStart = CGFloat(currentExon.end - gene.start) * geneScale
                let intronEnd = CGFloat(nextExon.start - gene.start) * geneScale
                let intronWidth = intronEnd - intronStart
                
                // Draw intron label if space is sufficient
                if intronWidth > 40 {
                    let intronLength = nextExon.start - currentExon.end - 1
                    let intronLabel = Text("I\(i+1)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.orange)
                    context.draw(intronLabel, at: CGPoint(x: (intronStart + intronEnd) / 2, y: trackY + trackHeight / 2 - 12), anchor: .center)
                    
                    // Intron bp count
                    let intronBP = Text("\(formatBP(intronLength))")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.orange.opacity(0.9))
                    context.draw(intronBP, at: CGPoint(x: (intronStart + intronEnd) / 2, y: trackY + trackHeight / 2 + 12), anchor: .center)
                }
            }
        }
        .frame(width: calculateDiagramWidth(), height: 40)
    }
    
    // Format bp number with K suffix for readability
    private func formatBP(_ bp: Int) -> String {
        if bp >= 1000000 {
            return String(format: "%.1fM", Double(bp) / 1000000.0)
        } else if bp >= 1000 {
            return String(format: "%.1fK", Double(bp) / 1000.0)
        } else {
            return "\(bp)"
        }
    }
    
    // Get exon color based on its region type
    private func getExonColor(_ exon: ExonModel) -> Color {
        guard let transcript = viewModel.transcripts.first(where: { $0.isCanonical }) else {
            return .green
        }
        
        // Check if in CDS
        if let translation = transcript.translation,
           exon.start <= translation.end && exon.end >= translation.start {
            return .blue
        }
        
        // Check if in 5' UTR
        if let utr5 = transcript.utr5,
           exon.start <= utr5.end && exon.end >= utr5.start {
            return .purple
        }
        
        // Check if in 3' UTR
        if let utr3 = transcript.utr3,
           exon.start <= utr3.end && exon.end >= utr3.start {
            return .indigo
        }
        
        return .green
    }
    
    // MARK: - Legend
    private var legendView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                LegendItem(color: .blue, label: "CDS")
                LegendItem(color: .purple, label: "5' UTR")
                LegendItem(color: .indigo, label: "3' UTR")
                LegendItem(color: .green, label: "Exon")
            }
            
            HStack(spacing: 12) {
                LegendItem(color: .orange, label: "Intron")
                LegendItem(color: .pink, label: "Promoter")
                LegendItem(color: .brown, label: "Downstream")
                LegendItem(color: .red, label: "Current (Blinking)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Helper Functions
    private func isExonInCDS(_ exon: ExonModel) -> Bool {
        guard let transcript = viewModel.transcripts.first(where: { $0.isCanonical }),
              let translation = transcript.translation else {
            return false
        }
        
        // Check if exon overlaps with CDS
        return exon.start <= translation.end && exon.end >= translation.start
    }
    
    private func calculateDiagramWidth() -> CGFloat {
        guard let gene = viewModel.selectedGene else { return 300 }
        
        let _ = gene.end - gene.start + 1
        let exonCount = viewModel.availableExons.count
        
        // Calculate width based on exon count
        // Aim for ~60px per exon, minimum 1000px, maximum 4000px
        let calculatedWidth = CGFloat(exonCount * 60)
        return min(max(calculatedWidth, 1000), 4000)
    }
    
    // MARK: - Detail Diagram (Zoomed view of current group)
    private var detailDiagram: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                guard let gene = viewModel.selectedGene else { return }
                
                let currentStart = sceneManager.displayStart
                let currentLength = sceneManager.displayLength
                let currentEnd = currentStart + currentLength
                
                // Convert to genomic coordinates
                let genomicStart = gene.start + currentStart
                let genomicEnd = gene.start + currentEnd
                
                let trackHeight: CGFloat = 120
                let trackY: CGFloat = 20
                
                // Draw background
                let bgRect = CGRect(x: 0, y: trackY, width: size.width, height: trackHeight)
                context.fill(Path(roundedRect: bgRect, cornerRadius: 8), with: .color(.gray.opacity(0.1)))
                
                // Find which exons overlap with current range
                var regionInfo = "Intron region"
                var regionColor = Color.orange
                
                for exon in viewModel.availableExons {
                    if genomicStart <= exon.end && genomicEnd >= exon.start {
                        regionColor = getExonColor(exon)
                        regionInfo = "Exon \(exon.rank)"
                        
                        // Check if in CDS
                        if let transcript = viewModel.transcripts.first(where: { $0.isCanonical }),
                           let translation = transcript.translation,
                           exon.start <= translation.end && exon.end >= translation.start {
                            regionInfo = "Exon \(exon.rank) (CDS)"
                        }
                        break
                    }
                }
                
                // Check for UTRs
                if let transcript = viewModel.transcripts.first(where: { $0.isCanonical }) {
                    if let utr5 = transcript.utr5, genomicStart >= utr5.start && genomicEnd <= utr5.end {
                        regionColor = .purple
                        regionInfo = "5' UTR"
                    }
                    
                    if let utr3 = transcript.utr3, genomicStart >= utr3.start && genomicEnd <= utr3.end {
                        regionColor = .indigo
                        regionInfo = "3' UTR"
                    }
                }
                
                // Draw main region box
                let mainRect = CGRect(x: 20, y: trackY, width: size.width - 40, height: trackHeight)
                context.fill(Path(roundedRect: mainRect, cornerRadius: 8), with: .color(regionColor))
                
                // Draw region label
                let regionLabel = Text(regionInfo)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                context.draw(regionLabel, at: CGPoint(x: size.width / 2, y: trackY + trackHeight / 2 - 10), anchor: .center)
                
                // Draw bp range
                let bpRange = Text("\(genomicStart) - \(genomicEnd) bp")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                context.draw(bpRange, at: CGPoint(x: size.width / 2, y: trackY + trackHeight / 2 + 10), anchor: .center)
                
                // Draw sequence if available - use currentSequence which matches SequenceBar
                if let sequence = currentSequence?.sequence, currentStart < sequence.count {
                    let endIdx = min(currentEnd, sequence.count)
                    let startIndex = sequence.index(sequence.startIndex, offsetBy: currentStart)
                    let endIndex = sequence.index(sequence.startIndex, offsetBy: endIdx)
                    let currentSeq = String(sequence[startIndex..<endIndex])
                    
                    // Draw sequence below
                    let seqText = Text(currentSeq)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.primary)
                    context.draw(seqText, at: CGPoint(x: size.width / 2, y: trackY + trackHeight + 10), anchor: .top)
                }
                
                // Draw position markers
                let markerY = trackY - 10
                let positions = [0.0, 0.25, 0.5, 0.75, 1.0]
                
                for pos in positions {
                    let x = 20 + (size.width - 40) * pos
                    let bpPos = genomicStart + Int(Double(currentLength) * pos)
                    
                    // Tick mark
                    var tick = Path()
                    tick.move(to: CGPoint(x: x, y: markerY))
                    tick.addLine(to: CGPoint(x: x, y: markerY + 6))
                    context.stroke(tick, with: .color(.gray), lineWidth: 1.5)
                    
                    // Position label
                    let posLabel = Text("\(bpPos)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.gray)
                    context.draw(posLabel, at: CGPoint(x: x, y: markerY - 2), anchor: .bottom)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Legend Item
struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    GeneStructureView(
        viewModel: GeneViewModel(),
        sceneManager: DNASceneManager(),
        currentSequence: nil
    )
}

