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

    // MARK: - Gene Library (API)
    // Fetch a list of genes from NCBI Gene DB using esearch + esummary
    func fetchGeneLibrary(term: String = "Homo sapiens[Organism]", retmax: Int = 20) async throws -> [GeneInfo] {
        return try await fetchGeneLibraryFiltered(term: term, retmax: retmax)
    }

    // Generalized: fetch with optional ESummary-based filters
    func fetchGeneLibraryFiltered(term: String, retmax: Int, filterGenetype: String? = nil, requireKeywords: [String]? = nil) async throws -> [GeneInfo] {
        // 1) Search gene IDs
        var searchComponents = URLComponents(string: "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi")
        searchComponents?.queryItems = [
            URLQueryItem(name: "db", value: "gene"),
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "retmax", value: String(retmax)),
            URLQueryItem(name: "retmode", value: "json")
        ]
        guard let searchURL = searchComponents?.url else { throw NCBIError.invalidURL }

        let (searchData, searchResp) = try await URLSession.shared.data(from: searchURL)
        guard let searchHTTP = searchResp as? HTTPURLResponse, searchHTTP.statusCode == 200 else { throw NCBIError.invalidResponse }
        let searchJSON = try JSONSerialization.jsonObject(with: searchData) as? [String: Any]
        let esearch = searchJSON?["esearchresult"] as? [String: Any]
        let idlist = esearch?["idlist"] as? [String] ?? []
        if idlist.isEmpty { return [] }

        // 2) Summarize to get symbols/descriptions
        var summaryComponents = URLComponents(string: "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi")
        summaryComponents?.queryItems = [
            URLQueryItem(name: "db", value: "gene"),
            URLQueryItem(name: "id", value: idlist.joined(separator: ",")),
            URLQueryItem(name: "retmode", value: "json")
        ]
        guard let summaryURL = summaryComponents?.url else { throw NCBIError.invalidURL }
        let (sumData, sumResp) = try await URLSession.shared.data(from: summaryURL)
        guard let sumHTTP = sumResp as? HTTPURLResponse, sumHTTP.statusCode == 200 else { throw NCBIError.invalidResponse }
        let sumJSON = try JSONSerialization.jsonObject(with: sumData) as? [String: Any]
        guard let result = sumJSON?["result"] as? [String: Any], let uids = result["uids"] as? [String] else { return [] }

        var genes: [GeneInfo] = []
        for uid in uids {
            guard let obj = result[uid] as? [String: Any] else { continue }
            // Optional filters
            if let wantType = filterGenetype?.lowercased() {
                let typeStr = (obj["genetype"] as? String)?.lowercased()
                if typeStr != wantType { continue }
            }
            if let keywords = requireKeywords, !keywords.isEmpty {
                let hay = [obj["description"] as? String, obj["nomenclaturename"] as? String, obj["summary"] as? String]
                    .compactMap { $0?.lowercased() }
                    .joined(separator: " ")
                if !keywords.contains(where: { hay.contains($0.lowercased()) }) { continue }
            }

            let symbol = (obj["name"] as? String) ?? (obj["nomenclaturesymbol"] as? String) ?? uid
            let fullName = (obj["nomenclaturename"] as? String) ?? (obj["description"] as? String) ?? symbol
            let chrom = (obj["chromosome"] as? String) ?? ""
            let gene = GeneInfo(
                id: uid,
                name: fullName,
                symbol: symbol,
                description: fullName,
                chromosome: chrom.isEmpty ? "" : chrom,
                diseases: []
            )
            genes.append(gene)
        }
        // Fallback: if type-filtered returns empty, try a keyword-based approach once
        if genes.isEmpty, filterGenetype != nil {
            let keywordFallback = try await fetchGeneLibraryFiltered(
                term: term,
                retmax: retmax,
                filterGenetype: nil,
                requireKeywords: ["protein", "coding"]
            )
            return keywordFallback
        }
        return genes
    }

    // MARK: - Low-level helpers for disjoint queries
    func esearchUIDs(term: String, retmax: Int) async throws -> [String] {
        var comps = URLComponents(string: "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi")
        comps?.queryItems = [
            URLQueryItem(name: "db", value: "gene"),
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "retmode", value: "json"),
            URLQueryItem(name: "retmax", value: String(max(0, retmax)))
        ]
        guard let url = comps?.url else { throw NCBIError.invalidURL }
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { throw NCBIError.invalidResponse }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let ids = ((json?["esearchresult"] as? [String: Any])?["idlist"] as? [String]) ?? []
        return ids
    }

    func esummaryGeneInfos(uids: [String]) async throws -> [GeneInfo] {
        guard !uids.isEmpty else { return [] }
        var all: [GeneInfo] = []
        let chunkSize = 100
        var idx = 0
        while idx < uids.count {
            let end = min(idx + chunkSize, uids.count)
            let chunk = Array(uids[idx..<end])
            var comps = URLComponents(string: "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi")
            comps?.queryItems = [
                URLQueryItem(name: "db", value: "gene"),
                URLQueryItem(name: "id", value: chunk.joined(separator: ",")),
                URLQueryItem(name: "retmode", value: "json")
            ]
            guard let url = comps?.url else { throw NCBIError.invalidURL }
            let (data, resp) = try await URLSession.shared.data(from: url)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { throw NCBIError.invalidResponse }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let result = json?["result"] as? [String: Any], let order = result["uids"] as? [String] else { idx = end; continue }
            for uid in order {
                guard let obj = result[uid] as? [String: Any] else { continue }
                let symbol = (obj["name"] as? String) ?? (obj["nomenclaturesymbol"] as? String) ?? uid
                let fullName = (obj["nomenclaturename"] as? String) ?? (obj["description"] as? String) ?? symbol
                let chrom = (obj["chromosome"] as? String) ?? ""
                all.append(GeneInfo(id: uid, name: fullName, symbol: symbol, description: fullName, chromosome: chrom, diseases: []))
            }
            idx = end
        }
        return all
    }

    func proteinCodingUIDs(retmax: Int) async throws -> [String] {
        // Start from Homo sapiens UID pool (larger to allow filtering), chunked
        let seedUIDs = try await esearchUIDs(term: "Homo sapiens[Organism]", retmax: max(200, retmax * 20))
        var picked: [String] = []
        let chunkSize = 100
        var idx = 0
        while idx < seedUIDs.count && picked.count < retmax {
            let end = min(idx + chunkSize, seedUIDs.count)
            let chunk = Array(seedUIDs[idx..<end])
            var comps = URLComponents(string: "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi")
            comps?.queryItems = [
                URLQueryItem(name: "db", value: "gene"),
                URLQueryItem(name: "id", value: chunk.joined(separator: ",")),
                URLQueryItem(name: "retmode", value: "json")
            ]
            if let url = comps?.url {
                let (data, resp) = try await URLSession.shared.data(from: url)
                if let http = resp as? HTTPURLResponse, http.statusCode == 200,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let result = json["result"] as? [String: Any], let order = result["uids"] as? [String] {
                    for uid in order {
                        guard let obj = result[uid] as? [String: Any] else { continue }
                        if (obj["genetype"] as? String)?.lowercased() == "protein-coding" {
                            picked.append(uid)
                            if picked.count >= retmax { break }
                        }
                    }
                }
            }
            idx = end
        }
        return picked
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

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let linksets = json?["linksets"] as? [[String: Any]] else { return [] }
        var ids: [String] = []
        for set in linksets {
            if let linksetdbs = set["linksetdbs"] as? [[String: Any]] {
                for db in linksetdbs where (db["dbto"] as? String) == "nuccore" {
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
            URLQueryItem(name: "seq_start", value: "47730491"),  // APOE gene start (T2T-CHM13)
            URLQueryItem(name: "seq_stop", value: "47734088")    // APOE gene end (~3.6kb)
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
