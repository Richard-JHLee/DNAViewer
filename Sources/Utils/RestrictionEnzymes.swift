//
//  RestrictionEnzymes.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import Foundation

struct RestrictionEnzyme: Identifiable, Codable {
    let id = UUID()
    let name: String
    let sequence: String
    let cutPosition: Int
    let recognitionSite: String
    let overhang: String
    
    enum CodingKeys: String, CodingKey {
        case name, sequence, cutPosition, recognitionSite, overhang
    }
}

struct RestrictionSite {
    let enzyme: RestrictionEnzyme
    let position: Int
    let matchedSequence: String
}

class RestrictionEnzymes {
    
    static let shared = RestrictionEnzymes()
    
    private var enzymes: [RestrictionEnzyme] = []
    
    private init() {
        loadEnzymes()
    }
    
    private func loadEnzymes() {
        // Load from JSON file
        guard let url = Bundle.main.url(forResource: "RestrictionSites", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let loadedEnzymes = try? JSONDecoder().decode([RestrictionEnzyme].self, from: data) else {
            // Fallback to default enzymes
            loadDefaultEnzymes()
            return
        }
        
        self.enzymes = loadedEnzymes
    }
    
    private func loadDefaultEnzymes() {
        enzymes = [
            RestrictionEnzyme(name: "EcoRI", sequence: "GAATTC", cutPosition: 1, recognitionSite: "G^AATTC", overhang: "5' overhang"),
            RestrictionEnzyme(name: "BamHI", sequence: "GGATCC", cutPosition: 1, recognitionSite: "G^GATCC", overhang: "5' overhang"),
            RestrictionEnzyme(name: "HindIII", sequence: "AAGCTT", cutPosition: 1, recognitionSite: "A^AGCTT", overhang: "5' overhang"),
            RestrictionEnzyme(name: "PstI", sequence: "CTGCAG", cutPosition: 5, recognitionSite: "CTGCA^G", overhang: "3' overhang"),
            RestrictionEnzyme(name: "SmaI", sequence: "CCCGGG", cutPosition: 3, recognitionSite: "CCC^GGG", overhang: "blunt"),
            RestrictionEnzyme(name: "XbaI", sequence: "TCTAGA", cutPosition: 1, recognitionSite: "T^CTAGA", overhang: "5' overhang"),
            RestrictionEnzyme(name: "NotI", sequence: "GCGGCCGC", cutPosition: 2, recognitionSite: "GC^GGCCGC", overhang: "5' overhang"),
            RestrictionEnzyme(name: "SacI", sequence: "GAGCTC", cutPosition: 5, recognitionSite: "GAGCT^C", overhang: "3' overhang")
        ]
    }
    
    func getAllEnzymes() -> [RestrictionEnzyme] {
        return enzymes
    }
    
    func findSites(in sequence: String, enzyme: RestrictionEnzyme) -> [RestrictionSite] {
        var sites: [RestrictionSite] = []
        let pattern = enzyme.sequence
        var searchRange = sequence.startIndex..<sequence.endIndex
        
        while let range = sequence.range(of: pattern, options: [], range: searchRange) {
            let position = sequence.distance(from: sequence.startIndex, to: range.lowerBound)
            let matchedSeq = String(sequence[range])
            
            sites.append(RestrictionSite(
                enzyme: enzyme,
                position: position,
                matchedSequence: matchedSeq
            ))
            
            searchRange = range.upperBound..<sequence.endIndex
        }
        
        return sites
    }
    
    func findAllSites(in sequence: String) -> [String: [RestrictionSite]] {
        var allSites: [String: [RestrictionSite]] = [:]
        
        for enzyme in enzymes {
            let sites = findSites(in: sequence, enzyme: enzyme)
            if !sites.isEmpty {
                allSites[enzyme.name] = sites
            }
        }
        
        return allSites
    }
    
    func digestSequence(_ sequence: String, with enzyme: RestrictionEnzyme) -> [String] {
        let sites = findSites(in: sequence, enzyme: enzyme)
        
        guard !sites.isEmpty else {
            return [sequence]
        }
        
        var fragments: [String] = []
        var lastPosition = 0
        
        for site in sites {
            let cutPosition = site.position + enzyme.cutPosition
            let startIndex = sequence.index(sequence.startIndex, offsetBy: lastPosition)
            let endIndex = sequence.index(sequence.startIndex, offsetBy: cutPosition)
            
            let fragment = String(sequence[startIndex..<endIndex])
            fragments.append(fragment)
            lastPosition = cutPosition
        }
        
        // Add last fragment
        if lastPosition < sequence.count {
            let startIndex = sequence.index(sequence.startIndex, offsetBy: lastPosition)
            let lastFragment = String(sequence[startIndex...])
            fragments.append(lastFragment)
        }
        
        return fragments
    }
}

