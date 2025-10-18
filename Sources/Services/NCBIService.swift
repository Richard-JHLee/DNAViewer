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
        print("🌐 NCBIService.fetchSequence called with: \(accession)")
        
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "db", value: "nuccore"),
            URLQueryItem(name: "id", value: accession),
            URLQueryItem(name: "rettype", value: "fasta"),
            URLQueryItem(name: "retmode", value: "text")
        ]
        
        guard let url = components?.url else {
            print("❌ Invalid URL")
            throw NCBIError.invalidURL
        }
        
        print("📡 Requesting: \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw NCBIError.invalidResponse
            }
            
            print("📥 HTTP Status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                throw NCBIError.invalidResponse
            }
            
            guard let fastaString = String(data: data, encoding: .utf8) else {
                print("❌ Failed to decode response data")
                throw NCBIError.parsingError
            }
            
            print("📄 Received FASTA data (\(data.count) bytes)")
            print("📄 First 200 chars: \(String(fastaString.prefix(200)))")
            
            let record = try FASTAParser.parse(fastaString)
            print("✅ Parsed: \(record.sequence.count)bp, accession: \(record.accession ?? "N/A")")
            
            return DNASequence(
                name: record.accession ?? "Unknown",
                accession: record.accession,
                sequence: record.sequence,
                summary: record.description
            )
        } catch let error as NCBIError {
            print("❌ NCBIError: \(error)")
            throw error
        } catch {
            print("❌ Network error: \(error.localizedDescription)")
            throw NCBIError.networkError(error)
        }
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

