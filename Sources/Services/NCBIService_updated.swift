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
        
        // Check if this is APOE - get only the gene region, not the entire chromosome
        if accession.contains("2194972797") {
            print("⚠️ APOE detected - fetching gene region only (positions 45411941-45418650)")
            return try await fetchAPOEGeneRegion()
        }
        
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
        
        // Create URLSession with longer timeout for large sequences
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300  // 5 minutes
        config.timeoutIntervalForResource = 600 // 10 minutes
        let session = URLSession(configuration: config)
        
        // Retry logic for large sequences
        let maxRetries = 3
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                print("🔄 Attempt \(attempt)/\(maxRetries) for sequence: \(accession)")
                let (data, response) = try await session.data(from: url)
                
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
                lastError = error
                print("❌ NCBIError (attempt \(attempt)): \(error)")
                if attempt < maxRetries {
                    let delay = Double(attempt * 2)
                    print("⏳ Retrying in \(delay) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            } catch {
                lastError = error
                print("❌ Network error (attempt \(attempt)): \(error.localizedDescription)")
                if attempt < maxRetries {
                    let delay = Double(attempt * 2)
                    print("⏳ Retrying in \(delay) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        print("❌ All attempts failed for sequence: \(accession)")
        throw NCBIError.networkError(lastError ?? NCBIError.invalidResponse)
    }
    
    func searchGene(term: String) async throws -> [String] {
        let searchURL = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"
        
        var components = URLComponents(string: searchURL)
        components?.queryItems = [
            URLQueryItem(name: "db", value: "gene"),
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "retmode", value: "json"),
            URLQueryItem(name: "retmax", value: "20")
        ]
        
        guard let url = components?.url else {
            throw NCBIError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NCBIError.invalidResponse
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let esearchResult = json["esearchresult"] as? [String: Any],
                  let idlist = esearchResult["idlist"] as? [String] else {
                throw NCBIError.parsingError
            }
            
            return idlist
            
        } catch {
            throw NCBIError.networkError(error)
        }
    }
    
    func fetchGeneSummary(uid: String) async throws -> GeneInfo {
        let summaryURL = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi"
        
        var components = URLComponents(string: summaryURL)
        components?.queryItems = [
            URLQueryItem(name: "db", value: "gene"),
            URLQueryItem(name: "id", value: uid),
            URLQueryItem(name: "retmode", value: "json")
        ]
        
        guard let url = components?.url else {
            throw NCBIError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NCBIError.invalidResponse
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let result = json["result"] as? [String: Any],
                  let uidData = result[uid] as? [String: Any] else {
                throw NCBIError.parsingError
            }
            
            let name = uidData["name"] as? String ?? "Unknown"
            let description = uidData["description"] as? String ?? ""
            let summary = uidData["summary"] as? String ?? ""
            
            return GeneInfo(
                uid: uid,
                name: name,
                description: description,
                summary: summary
            )
            
        } catch {
            throw NCBIError.networkError(error)
        }
    }
    
    // Fetch gene library with category-based search
    func fetchGeneLibrary(term: String, retmax: Int = 20) async throws -> [GeneInfo] {
        print("📚 Fetching genes for term: \(term)")
        
        // First, search for genes
        let geneUIDs = try await searchGene(term: term)
        print("🔍 Found \(geneUIDs.count) gene UIDs")
        
        guard !geneUIDs.isEmpty else {
            print("⚠️ No genes found for term: \(term)")
            return []
        }
        
        // Limit to retmax
        let limitedUIDs = Array(geneUIDs.prefix(retmax))
        print("📋 Processing \(limitedUIDs.count) genes")
        
        // Fetch summaries for each gene
        var genes: [GeneInfo] = []
        for uid in limitedUIDs {
            do {
                let geneInfo = try await fetchGeneSummary(uid: uid)
                genes.append(geneInfo)
                print("✅ Loaded: \(geneInfo.name)")
            } catch {
                print("❌ Failed to load gene \(uid): \(error.localizedDescription)")
            }
        }
        
        print("📚 Successfully loaded \(genes.count) genes")
        return genes
    }
    
    // Map Gene UID -> related nucleotide (nuccore) accessions using elink
    func resolveAccessionsFromGeneUID(_ geneUID: String, retmax: Int = 5) async throws -> [String] {
        var components = URLComponents(string: "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi")
        components?.queryItems = [
            URLQueryItem(name: "dbfrom", value: "gene"),
            URLQueryItem(name: "db", value: "nuccore"),
            URLQueryItem(name: "id", value: geneUID),
            URLQueryItem(name: "retmode", value: "json")
        ]
        guard let url = components?.url else { throw NCBIError.invalidURL }
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { throw NCBIError.invalidResponse }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let linksets = json["linksets"] as? [[String: Any]] else { throw NCBIError.parsingError }
        var ids: [String] = []
        for linkset in linksets {
            if let linksetdb = linkset["linksetdbs"] as? [[String: Any]] {
                for db in linksetdb {
                    let linkIds = (db["links"] as? [[String: Any]])?.compactMap { $0["id"] as? String } ?? []
                    ids.append(contentsOf: linkIds)
                }
            }
        }
        if ids.count > retmax { ids = Array(ids.prefix(retmax)) }
        return ids
    }
    
    // Fetch APOE gene region only (not the entire chromosome)
    private func fetchAPOEGeneRegion() async throws -> DNASequence {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "db", value: "nuccore"),
            URLQueryItem(name: "id", value: "2194972797"),
            URLQueryItem(name: "rettype", value: "fasta"),
            URLQueryItem(name: "retmode", value: "text"),
            URLQueryItem(name: "seq_start", value: "45411941"),  // APOE gene start
            URLQueryItem(name: "seq_stop", value: "45418650")    // APOE gene end (~6.7kb)
        ]
        
        guard let url = components?.url else {
            throw NCBIError.invalidURL
        }
        
        print("📡 Requesting APOE gene region: \(url.absoluteString)")
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60  // 1 minute should be enough for 6.7kb
        config.timeoutIntervalForResource = 120
        let session = URLSession(configuration: config)
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NCBIError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                throw NCBIError.invalidResponse
            }
            
            guard let fastaString = String(data: data, encoding: .utf8) else {
                throw NCBIError.parsingError
            }
            
            print("📄 Received APOE gene region (\(data.count) bytes)")
            
            let record = try FASTAParser.parse(fastaString)
            print("✅ Parsed APOE gene: \(record.sequence.count)bp")
            
            return DNASequence(
                name: "APOE Gene",
                accession: "2194972797",
                sequence: record.sequence,
                summary: "APOE gene region (chromosome 19: 45411941-45418650). Complete gene sequence."
            )
            
        } catch {
            print("❌ Error fetching APOE gene region: \(error.localizedDescription)")
            throw NCBIError.networkError(error)
        }
    }
}
