//
//  GenomeMapView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-22.
//

import SwiftUI

struct GenomeMapView: View {
    let length: Int
    let genes: [GeneMark]
    let title: String
    
    var body: some View {
        VStack {
            Text("Genome Map")
                .font(.largeTitle)
                .padding()
            
            Text("Title: \(title)")
                .font(.headline)
            
            Text("Length: \(length)")
                .font(.subheadline)
            
            Text("Genes: \(genes.count)")
                .font(.subheadline)
            
            Spacer()
            
            Text("Genome Map functionality will be implemented here")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .navigationTitle("Genome Map")
    }
}

#Preview {
    GenomeMapView(length: 1000, genes: [], title: "Chr17")
}