//
//  RestrictionEnzymes.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import Foundation

// MARK: - Enhanced Models

enum Overhang: String, Codable, CaseIterable {
    case fivePrime = "5' overhang"
    case threePrime = "3' overhang"
    case blunt = "Blunt"
}

struct RestrictionEnzyme: Identifiable, Codable, Hashable {
    let id = UUID()
    let name: String
    let sequence: String
    let cutPosition: Int
    let recognitionSite: String
    let overhang: String
    
    enum CodingKeys: String, CodingKey {
        case name, sequence, cutPosition, recognitionSite, overhang
    }
    
    /// caret('^')를 제외한 순수 패턴 (IUPAC 포함 가능)
    var rawPattern: String {
        recognitionSite.replacingOccurrences(of: "^", with: "")
    }

    /// caret 위치 인덱스(상단가닥 기준, 0-based)
    var cutIndex: Int {
        (recognitionSite.firstIndex(of: "^").map { recognitionSite.distance(from: recognitionSite.startIndex, to: $0) }) ?? 0
    }
}

struct RestrictionHit: Identifiable, Hashable {
    var id: String { "\(enzyme.name)-\(position)" }
    let enzyme: RestrictionEnzyme
    let position: Int      // 1-based 시작 인덱스 (인식서열의 첫 글자 기준)
}

struct RestrictionSite {
    let enzyme: RestrictionEnzyme
    let position: Int
    let matchedSequence: String
}

// MARK: - IUPAC → RegEx

fileprivate let iupacMap: [Character: String] = [
    "A":"A", "C":"C", "G":"G", "T":"T", "U":"U",
    "R":"[AG]", "Y":"[CT]", "S":"[GC]", "W":"[AT]",
    "K":"[GT]", "M":"[AC]",
    "B":"[CGT]", "D":"[AGT]", "H":"[ACT]", "V":"[ACG]",
    "N":"[ACGT]"
]

fileprivate func regexFromIUPAC(_ pattern: String) throws -> NSRegularExpression {
    let pat = pattern.uppercased().compactMap { ch -> String? in
        if ch == "^" { return nil }                // 제거
        if let m = iupacMap[ch] { return m }       // IUPAC 매핑
        return NSRegularExpression.escapedPattern(for: String(ch))
    }.joined()
    return try NSRegularExpression(pattern: pat)
}

// MARK: - Advanced Analyzer

final class RestrictionSiteAnalyzer {
    /// sequence: A/T/G/C 로만 구성 권장(소문자 허용). 비정상 문자는 무시/스킵 처리.
    func analyze(sequence: String, enzymes: [RestrictionEnzyme]) -> [String: [RestrictionHit]] {
        let seq = sequence.uppercased().filter { "ACGT".contains($0) }
        guard !seq.isEmpty else { return [:] }

        var result: [String: [RestrictionHit]] = [:]

        for ez in enzymes {
            do {
                let regex = try regexFromIUPAC(ez.rawPattern)
                let matches = regex.matches(in: seq, range: NSRange(location: 0, length: seq.utf16.count))

                let hits: [RestrictionHit] = matches.compactMap { m in
                    // NSRange → String.Index 변환
                    guard let r = Range(m.range, in: seq) else { return nil }
                    let start0 = seq.distance(from: seq.startIndex, to: r.lowerBound) // 0-based
                    return RestrictionHit(enzyme: ez, position: start0 + 1)           // 1-based 표시
                }
                if !hits.isEmpty {
                    result[ez.name] = hits
                }
            } catch {
                print("Regex error for \(ez.name): \(error)")
            }
        }
        return result
    }
}

// MARK: - Enhanced Library

let defaultEnzymes: [RestrictionEnzyme] = [
    // 주석: 인식서열 / 절단위치 / 오버행
    RestrictionEnzyme(name: "EcoRI", sequence: "GAATTC", cutPosition: 1, recognitionSite: "G^AATTC", overhang: "5' overhang"),
    RestrictionEnzyme(name: "BamHI", sequence: "GGATCC", cutPosition: 1, recognitionSite: "G^GATCC", overhang: "5' overhang"),
    RestrictionEnzyme(name: "HindIII", sequence: "AAGCTT", cutPosition: 1, recognitionSite: "A^AGCTT", overhang: "5' overhang"),
    RestrictionEnzyme(name: "PstI", sequence: "CTGCAG", cutPosition: 5, recognitionSite: "CTGCA^G", overhang: "3' overhang"),
    RestrictionEnzyme(name: "SacI", sequence: "GAGCTC", cutPosition: 5, recognitionSite: "GAGCT^C", overhang: "3' overhang"),
    RestrictionEnzyme(name: "NotI", sequence: "GCGGCCGC", cutPosition: 2, recognitionSite: "GC^GGCCGC", overhang: "5' overhang"),
    RestrictionEnzyme(name: "XbaI", sequence: "TCTAGA", cutPosition: 1, recognitionSite: "T^CTAGA", overhang: "5' overhang"),
    RestrictionEnzyme(name: "SalI", sequence: "GTCGAC", cutPosition: 1, recognitionSite: "G^TCGAC", overhang: "5' overhang"),
    RestrictionEnzyme(name: "XhoI", sequence: "CTCGAG", cutPosition: 1, recognitionSite: "C^TCGAG", overhang: "5' overhang"),
    RestrictionEnzyme(name: "KpnI", sequence: "GGTACC", cutPosition: 5, recognitionSite: "GGTAC^C", overhang: "3' overhang"),
    RestrictionEnzyme(name: "SmaI", sequence: "CCCGGG", cutPosition: 3, recognitionSite: "CCC^GGG", overhang: "blunt"),
    RestrictionEnzyme(name: "EcoRV", sequence: "GATATC", cutPosition: 3, recognitionSite: "GAT^ATC", overhang: "blunt"),
    RestrictionEnzyme(name: "DraI", sequence: "TTTAAA", cutPosition: 3, recognitionSite: "TTT^AAA", overhang: "blunt"),
    RestrictionEnzyme(name: "ScaI", sequence: "AGTACT", cutPosition: 3, recognitionSite: "AGT^ACT", overhang: "blunt"),
    RestrictionEnzyme(name: "PvuII", sequence: "CAGCTG", cutPosition: 3, recognitionSite: "CAG^CTG", overhang: "blunt")
    // 필요 시 수백 종까지 확장 가능 (IUPAC 포함 인식서열 지원)
]

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

