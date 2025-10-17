//
//  PDBService.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import Foundation

class PDBService {
    
    enum PDBError: Error {
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case parsingError
    }
    
    static let shared = PDBService()
    
    private let baseURL = "https://files.rcsb.org/download"
    
    private init() {}
    
    func fetchStructure(pdbID: String) async throws -> String {
        let urlString = "\(baseURL)/\(pdbID.uppercased()).cif"
        
        guard let url = URL(string: urlString) else {
            throw PDBError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PDBError.invalidResponse
        }
        
        guard let cifString = String(data: data, encoding: .utf8) else {
            throw PDBError.parsingError
        }
        
        return cifString
    }
    
    func searchDNA(keyword: String) async throws -> [String] {
        let searchURL = "https://search.rcsb.org/rcsbsearch/v2/query"
        
        guard let url = URL(string: searchURL) else {
            throw PDBError.invalidURL
        }
        
        let query = """
        {
            "query": {
                "type": "terminal",
                "service": "text",
                "parameters": {
                    "attribute": "struct_keywords.pdbx_keywords",
                    "operator": "contains_phrase",
                    "value": "\(keyword)"
                }
            },
            "return_type": "entry",
            "request_options": {
                "results_content_type": ["experimental"],
                "pager": {
                    "start": 0,
                    "rows": 10
                }
            }
        }
        """
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = query.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PDBError.invalidResponse
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let resultSet = json?["result_set"] as? [[String: Any]] ?? []
        
        return resultSet.compactMap { $0["identifier"] as? String }
    }
}

