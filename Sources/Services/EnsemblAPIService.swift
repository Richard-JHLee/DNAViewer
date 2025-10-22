//
//  EnsemblAPIService.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-22.
//

import Foundation

class EnsemblAPIService: ObservableObject {
    static let shared = EnsemblAPIService()
    
    private let baseURL = "https://rest.ensembl.org"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Gene Lookup
    func lookupSymbol(_ symbol: String) async throws -> GeneModel {
        let urlString = "\(baseURL)/lookup/symbol/homo_sapiens/\(symbol)?content-type=application/json"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        let lookupResponse = try JSONDecoder().decode(EnsemblLookupResponse.self, from: data)
        return lookupResponse.toGeneModel()
    }
    
    // MARK: - Neighboring Genes
    func getNeighboringGenes(for gene: GeneModel, range: Int = 5_000_000) async throws -> [GeneModel] {
        let start = max(1, gene.start - range)
        let end = gene.end + range
        let chr = gene.chromosome
        
        let urlString = "\(baseURL)/overlap/region/homo_sapiens/\(chr):\(start)-\(end)?feature=gene;content-type=application/json"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        let overlapResponses = try JSONDecoder().decode([EnsemblOverlapResponse].self, from: data)
        return overlapResponses.map { $0.toGeneModel() }
    }
    
    // MARK: - Transcripts
    func getTranscripts(for gene: GeneModel) async throws -> [TranscriptModel] {
        let urlString = "\(baseURL)/lookup/id/\(gene.id)?expand=1;content-type=application/json"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let transcripts = json?["Transcript"] as? [[String: Any]] else {
            throw APIError.parsingFailed
        }
        
        var transcriptModels: [TranscriptModel] = []
        for transcriptData in transcripts {
            if let transcriptJson = try? JSONSerialization.data(withJSONObject: transcriptData),
               let transcript = try? JSONDecoder().decode(EnsemblTranscriptResponse.self, from: transcriptJson) {
                transcriptModels.append(transcript.toTranscriptModel())
            }
        }
        
        return transcriptModels
    }
    
    // MARK: - Sequence Retrieval
    func getSequence(for gene: GeneModel, type: GroupType, meta: GroupMeta) async throws -> String {
        switch type {
        case .gene:
            return try await getGeneSequence(gene)
        case .transcript:
            guard let transcriptID = meta.transcriptID else {
                throw APIError.missingParameter
            }
            return try await getTranscriptSequence(transcriptID)
        case .exon:
            guard let transcriptID = meta.transcriptID,
                  let exonIndex = meta.exonIndex else {
                throw APIError.missingParameter
            }
            return try await getExonSequence(gene, transcriptID: transcriptID, exonIndex: exonIndex)
        case .region:
            guard let start = meta.regionStart,
                  let end = meta.regionEnd else {
                throw APIError.missingParameter
            }
            return try await getRegionSequence(gene, start: start, end: end)
        }
    }
    
    private func getGeneSequence(_ gene: GeneModel) async throws -> String {
        let urlString = "\(baseURL)/sequence/id/\(gene.id)?content-type=text/plain"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    private func getTranscriptSequence(_ transcriptID: String) async throws -> String {
        let urlString = "\(baseURL)/sequence/id/\(transcriptID)?content-type=text/plain"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    private func getExonSequence(_ gene: GeneModel, transcriptID: String, exonIndex: Int) async throws -> String {
        // First get transcript info to find exon coordinates
        let transcripts = try await getTranscripts(for: gene)
        guard let transcript = transcripts.first(where: { $0.id == transcriptID }),
              exonIndex < transcript.exons.count else {
            throw APIError.invalidParameter
        }
        
        let exon = transcript.exons[exonIndex]
        return try await getRegionSequence(gene, start: exon.start, end: exon.end)
    }
    
    private func getRegionSequence(_ gene: GeneModel, start: Int, end: Int) async throws -> String {
        let strand = gene.strand == 1 ? "1" : "-1"
        let urlString = "\(baseURL)/sequence/region/homo_sapiens/\(gene.chromosome):\(start)..\(end):\(strand)?content-type=text/plain"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

// MARK: - Error Handling
enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed
    case parsingFailed
    case missingParameter
    case invalidParameter
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed:
            return "Request failed"
        case .parsingFailed:
            return "Failed to parse response"
        case .missingParameter:
            return "Missing required parameter"
        case .invalidParameter:
            return "Invalid parameter"
        }
    }
}
