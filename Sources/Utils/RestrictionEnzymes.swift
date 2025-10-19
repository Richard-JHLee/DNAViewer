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
    let isoschizomers: [String]?
    let organism: String?
    let supplier: [String]?
    
    enum CodingKeys: String, CodingKey {
        case name, sequence, cutPosition, recognitionSite, overhang
        case isoschizomers, organism, supplier
    }
    
    static var all: [RestrictionEnzyme] {
        guard let url = Bundle.main.url(forResource: "RestrictionEnzymes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let enzymes = try? JSONDecoder().decode([RestrictionEnzyme].self, from: data) else {
            return []
        }
        return enzymes
    }
    
    /// caret('^')를 제외한 순수 패턴 (IUPAC 포함 가능)
    var rawPattern: String {
        recognitionSite.replacingOccurrences(of: "^", with: "")
    }

    /// caret 위치 인덱스(상단가닥 기준, 0-based)
    var cutIndex: Int {
        (recognitionSite.firstIndex(of: "^").map { recognitionSite.distance(from: recognitionSite.startIndex, to: $0) }) ?? 0
    }
    
    // Hashable implementation based on name only
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: RestrictionEnzyme, rhs: RestrictionEnzyme) -> Bool {
        return lhs.name == rhs.name
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
    RestrictionEnzyme(name: "EcoRI", sequence: "GAATTC", cutPosition: 1, recognitionSite: "G^AATTC", overhang: "5' overhang", isoschizomers: nil, organism: nil, supplier: nil),
    RestrictionEnzyme(name: "BamHI", sequence: "GGATCC", cutPosition: 1, recognitionSite: "G^GATCC", overhang: "5' overhang", isoschizomers: nil, organism: nil, supplier: nil),
    RestrictionEnzyme(name: "HindIII", sequence: "AAGCTT", cutPosition: 1, recognitionSite: "A^AGCTT", overhang: "5' overhang", isoschizomers: nil, organism: nil, supplier: nil),
    RestrictionEnzyme(name: "PstI", sequence: "CTGCAG", cutPosition: 5, recognitionSite: "CTGCA^G", overhang: "3' overhang", isoschizomers: nil, organism: nil, supplier: nil),
    RestrictionEnzyme(name: "SacI", sequence: "GAGCTC", cutPosition: 5, recognitionSite: "GAGCT^C", overhang: "3' overhang", isoschizomers: nil, organism: nil, supplier: nil),
    RestrictionEnzyme(name: "NotI", sequence: "GCGGCCGC", cutPosition: 2, recognitionSite: "GC^GGCCGC", overhang: "5' overhang", isoschizomers: nil, organism: nil, supplier: nil),
    RestrictionEnzyme(name: "XbaI", sequence: "TCTAGA", cutPosition: 1, recognitionSite: "T^CTAGA", overhang: "5' overhang", isoschizomers: nil, organism: nil, supplier: nil),
    RestrictionEnzyme(name: "SalI", sequence: "GTCGAC", cutPosition: 1, recognitionSite: "G^TCGAC", overhang: "5' overhang", isoschizomers: nil, organism: nil, supplier: nil),
    RestrictionEnzyme(name: "XhoI", sequence: "CTCGAG", cutPosition: 1, recognitionSite: "C^TCGAG", overhang: "5' overhang", isoschizomers: nil, organism: nil, supplier: nil),
    RestrictionEnzyme(name: "KpnI", sequence: "GGTACC", cutPosition: 5, recognitionSite: "GGTAC^C", overhang: "3' overhang", isoschizomers: nil, organism: nil, supplier: nil),
    RestrictionEnzyme(name: "SmaI", sequence: "CCCGGG", cutPosition: 3, recognitionSite: "CCC^GGG", overhang: "blunt", isoschizomers: nil, organism: nil, supplier: nil),
    RestrictionEnzyme(name: "EcoRV", sequence: "GATATC", cutPosition: 3, recognitionSite: "GAT^ATC", overhang: "blunt", isoschizomers: nil, organism: nil, supplier: nil),
    RestrictionEnzyme(name: "DraI", sequence: "TTTAAA", cutPosition: 3, recognitionSite: "TTT^AAA", overhang: "blunt", isoschizomers: nil, organism: nil, supplier: nil),
    RestrictionEnzyme(name: "ScaI", sequence: "AGTACT", cutPosition: 3, recognitionSite: "AGT^ACT", overhang: "blunt", isoschizomers: nil, organism: nil, supplier: nil),
    RestrictionEnzyme(name: "PvuII", sequence: "CAGCTG", cutPosition: 3, recognitionSite: "CAG^CTG", overhang: "blunt", isoschizomers: nil, organism: nil, supplier: nil)
    // 필요 시 수백 종까지 확장 가능 (IUPAC 포함 인식서열 지원)
]

class RestrictionEnzymes {
    
    static let shared = RestrictionEnzymes()
    
    private var enzymes: [RestrictionEnzyme] = []
    private var isLoaded: Bool = false
    private let loadQueue = DispatchQueue(label: "com.avas.DNAViewer.restrictionEnzymes", qos: .userInitiated)
    
    private init() {
        // 초기화 시점에는 로드하지 않음 (lazy loading)
    }
    
    /// 효소 데이터를 한 번만 로드 (thread-safe)
    private func ensureLoaded() {
        loadQueue.sync {
            guard !isLoaded else { return }
            loadEnzymes()
            isLoaded = true
        }
    }
    
    private func loadEnzymes() {
        print("🧬 Loading restriction enzymes from JSON...")
        
        // 1. 먼저 번들의 JSON 파일에서 로드 시도
        if let url = Bundle.main.url(forResource: "RestrictionEnzymes", withExtension: "json") {
            print("📦 Found RestrictionEnzymes.json in bundle")
            do {
                let data = try Data(contentsOf: url)
                let loadedEnzymes = try JSONDecoder().decode([RestrictionEnzyme].self, from: data)
                self.enzymes = loadedEnzymes
                print("✅ Loaded \(loadedEnzymes.count) restriction enzymes from JSON")
                return
            } catch {
                print("⚠️ Failed to load JSON: \(error.localizedDescription)")
            }
        }
        
        // 2. 번들에 없으면 하드코딩된 기본 효소 사용
        print("📝 Using default enzyme library")
        self.enzymes = defaultEnzymes
        print("✅ Loaded \(defaultEnzymes.count) default restriction enzymes")
    }
    
    func getAllEnzymes() -> [RestrictionEnzyme] {
        ensureLoaded()
        return enzymes
    }
    
    func findSites(in sequence: String, enzyme: RestrictionEnzyme) -> [RestrictionSite] {
        ensureLoaded()
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
        ensureLoaded()
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
        ensureLoaded()
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

