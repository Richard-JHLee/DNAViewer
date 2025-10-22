//
//  SequenceBoxView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-22.
//

import SwiftUI

struct SequenceBoxView: View {
    let sequence: String
    
    var body: some View {
        Canvas { context, size in
            drawSequence(context: context, size: size)
        }
        .frame(height: 60)
        .background(Color(.systemBackground))
    }
    
    private func drawSequence(context: GraphicsContext, size: CGSize) {
        let boxSize: CGFloat = 30
        let spacing: CGFloat = 5
        let totalWidth = CGFloat(sequence.count) * (boxSize + spacing) - spacing
        let startX = (size.width - totalWidth) / 2
        let centerY = size.height / 2
        
        for (index, base) in sequence.enumerated() {
            let x = startX + CGFloat(index) * (boxSize + spacing)
            let rect = CGRect(
                x: x,
                y: centerY - boxSize/2,
                width: boxSize,
                height: boxSize
            )
            
            // Draw base box
            drawBaseBox(context: context, base: base, rect: rect)
            
            // Draw base letter
            drawBaseLetter(context: context, base: base, rect: rect)
        }
    }
    
    private func drawBaseBox(context: GraphicsContext, base: Character, rect: CGRect) {
        let color = SequenceProcessor.shared.getSequenceColor(base)
        
        // Draw box background
        var boxPath = Path()
        boxPath.addRoundedRect(in: rect, cornerSize: CGSize(width: 4, height: 4))
        context.fill(boxPath, with: .color(color))
        
        // Draw box border
        context.stroke(boxPath, with: .color(.white), style: StrokeStyle(lineWidth: 1))
    }
    
    private func drawBaseLetter(context: GraphicsContext, base: Character, rect: CGRect) {
        let letter = String(base).uppercased()
        let font = Font.system(size: 16, weight: .bold)
        let text = Text(letter)
            .font(font)
            .foregroundColor(.white)
        
        context.draw(text, at: CGPoint(x: rect.midX, y: rect.midY), anchor: .center)
    }
}

// MARK: - Alternative Grid Layout
struct SequenceGridView: View {
    let sequence: String
    let columns: Int
    
    init(sequence: String, columns: Int = 10) {
        self.sequence = sequence
        self.columns = columns
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(30), spacing: 5), count: columns), spacing: 5) {
            ForEach(Array(sequence.enumerated()), id: \.offset) { index, base in
                BaseBoxView(base: base)
            }
        }
        .padding()
    }
}

struct BaseBoxView: View {
    let base: Character
    
    var body: some View {
        let color = SequenceProcessor.shared.getSequenceColor(base)
        
        Text(String(base).uppercased())
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 30, height: 30)
            .background(color)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white, lineWidth: 1)
            )
    }
}

#Preview {
    VStack(spacing: 20) {
        SequenceBoxView(sequence: "ATGCGTACGTATGCAGTCAG")
        
        SequenceGridView(sequence: "ATGCGTACGTATGCAGTCAG")
    }
    .padding()
}
