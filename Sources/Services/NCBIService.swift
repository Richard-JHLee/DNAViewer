//
//  NCBIService.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import Foundation

class NCBIService {
    
    enum NCBIError: Error {
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case parsingError
    }
    
    static let shared = NCBIService()
    
    private let baseURL = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi"
    
    private init() {}
    
    func fetchSequence(accession: String) async throws -> DNASequence {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "db", value: "nuccore"),
            URLQueryItem(name: "id", value: accession),
            URLQueryItem(name: "rettype", value: "fasta"),
            URLQueryItem(name: "retmode", value: "text")
        ]
        
        guard let url = components?.url else {
            throw NCBIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NCBIError.invalidResponse
        }
        
        guard let fastaString = String(data: data, encoding: .utf8) else {
            throw NCBIError.parsingError
        }
        
        let record = try FASTAParser.parse(fastaString)
        
        return DNASequence(
            name: record.accession ?? "Unknown",
            accession: record.accession,
            sequence: record.sequence,
            summary: record.description
        )
    }
    
    func searchGene(term: String) async throws -> [String] {
        let searchURL = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"
        
        var components = URLComponents(string: searchURL)
        components?.queryItems = [
            URLQueryItem(name: "db", value: "nuccore"),
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "retmax", value: "10"),
            URLQueryItem(name: "retmode", value: "json")
        ]
        
        guard let url = components?.url else {
            throw NCBIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NCBIError.invalidResponse
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let esearchresult = json?["esearchresult"] as? [String: Any]
        let idlist = esearchresult?["idlist"] as? [String] ?? []
        
        return idlist
    }
}

