//
//  FASTAParser.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import Foundation

class FASTAParser {
    
    enum FASTAError: Error {
        case invalidFormat
        case emptySequence
        case invalidCharacters
    }
    
    struct FASTARecord {
        let header: String
        let sequence: String
        let accession: String?
        let description: String?
    }
    
    static func parse(_ fastaString: String) throws -> FASTARecord {
        let lines = fastaString.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard let firstLine = lines.first, firstLine.hasPrefix(">") else {
            throw FASTAError.invalidFormat
        }
        
        let header = String(firstLine.dropFirst())
        let sequenceLines = lines.dropFirst()
        let sequence = sequenceLines.joined().uppercased()
        
        guard !sequence.isEmpty else {
            throw FASTAError.emptySequence
        }
        
        // Validate sequence contains only valid DNA bases
        let validBases = CharacterSet(charactersIn: "ATGCN")
        let sequenceSet = CharacterSet(charactersIn: sequence)
        guard sequenceSet.isSubset(of: validBases) else {
            throw FASTAError.invalidCharacters
        }
        
        // Try to extract accession from header
        let accession = extractAccession(from: header)
        
        return FASTARecord(
            header: header,
            sequence: sequence,
            accession: accession,
            description: header
        )
    }
    
    static func parseMultiple(_ fastaString: String) throws -> [FASTARecord] {
        var records: [FASTARecord] = []
        var currentHeader: String?
        var currentSequence: [String] = []
        
        let lines = fastaString.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        for line in lines {
            if line.hasPrefix(">") {
                // Save previous record if exists
                if let header = currentHeader, !currentSequence.isEmpty {
                    let sequence = currentSequence.joined().uppercased()
                    let accession = extractAccession(from: header)
                    records.append(FASTARecord(
                        header: header,
                        sequence: sequence,
                        accession: accession,
                        description: header
                    ))
                }
                // Start new record
                currentHeader = String(line.dropFirst())
                currentSequence = []
            } else if !line.isEmpty {
                currentSequence.append(line)
            }
        }
        
        // Save last record
        if let header = currentHeader, !currentSequence.isEmpty {
            let sequence = currentSequence.joined().uppercased()
            let accession = extractAccession(from: header)
            records.append(FASTARecord(
                header: header,
                sequence: sequence,
                accession: accession,
                description: header
            ))
        }
        
        guard !records.isEmpty else {
            throw FASTAError.invalidFormat
        }
        
        return records
    }
    
    private static func extractAccession(from header: String) -> String? {
        // Try to find accession patterns like NM_000546, NC_000017, etc.
        let pattern = #"([A-Z]{2}_\d+\.\d+)"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: header, options: [], range: NSRange(header.startIndex..., in: header)),
           let range = Range(match.range, in: header) {
            return String(header[range])
        }
        
        // Try simpler pattern
        let components = header.components(separatedBy: "|")
        if components.count > 1 {
            return components[1].trimmingCharacters(in: .whitespaces)
        }
        
        return nil
    }
    
    static func format(header: String, sequence: String, lineWidth: Int = 80) -> String {
        var result = ">\(header)\n"
        
        var startIndex = sequence.startIndex
        while startIndex < sequence.endIndex {
            let endIndex = sequence.index(startIndex, offsetBy: lineWidth, limitedBy: sequence.endIndex) ?? sequence.endIndex
            result += sequence[startIndex..<endIndex] + "\n"
            startIndex = endIndex
        }
        
        return result
    }
}

