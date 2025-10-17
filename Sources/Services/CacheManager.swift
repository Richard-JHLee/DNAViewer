//
//  CacheManager.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import Foundation

class CacheManager {
    
    static let shared = CacheManager()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("DNAViewer", isDirectory: true)
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Sequence Caching
    
    func cacheSequence(_ sequence: DNASequence, forKey key: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(sequence)
        
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        try data.write(to: fileURL)
    }
    
    func loadSequence(forKey key: String) throws -> DNASequence? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        return try decoder.decode(DNASequence.self, from: data)
    }
    
    // MARK: - FASTA File Caching
    
    func cacheFASTA(_ fastaString: String, forKey key: String) throws {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).fasta")
        try fastaString.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    func loadFASTA(forKey key: String) throws -> String? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).fasta")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        return try String(contentsOf: fileURL, encoding: .utf8)
    }
    
    // MARK: - PDB Structure Caching
    
    func cachePDB(_ cifString: String, forKey key: String) throws {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cif")
        try cifString.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    func loadPDB(forKey key: String) throws -> String? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cif")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        return try String(contentsOf: fileURL, encoding: .utf8)
    }
    
    // MARK: - Recent Items
    
    func saveRecentItem(_ item: RecentItem) throws {
        var recentItems = loadRecentItems()
        
        // Remove if already exists
        recentItems.removeAll { $0.id == item.id }
        
        // Add to front
        recentItems.insert(item, at: 0)
        
        // Keep only last 20 items
        if recentItems.count > 20 {
            recentItems = Array(recentItems.prefix(20))
        }
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(recentItems)
        let fileURL = cacheDirectory.appendingPathComponent("recent_items.json")
        try data.write(to: fileURL)
    }
    
    func loadRecentItems() -> [RecentItem] {
        let fileURL = cacheDirectory.appendingPathComponent("recent_items.json")
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let items = try? JSONDecoder().decode([RecentItem].self, from: data) else {
            return []
        }
        
        return items
    }
    
    // MARK: - Cache Management
    
    func clearCache() throws {
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for fileURL in contents {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    func getCacheSize() throws -> Int64 {
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
        
        var totalSize: Int64 = 0
        for fileURL in contents {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let fileSize = attributes[.size] as? Int64 {
                totalSize += fileSize
            }
        }
        
        return totalSize
    }
}

struct RecentItem: Identifiable, Codable {
    let id: String
    let name: String
    let type: String // "sequence", "pdb", "local"
    let date: Date
    let thumbnailPath: String?
    
    init(id: String = UUID().uuidString, name: String, type: String, date: Date = Date(), thumbnailPath: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.date = date
        self.thumbnailPath = thumbnailPath
    }
}

