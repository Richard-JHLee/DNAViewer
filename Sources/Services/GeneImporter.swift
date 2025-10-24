//
//  GeneImporter.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-18.
//

import Foundation

// Helper function to extract gene symbol from text
private func extractGeneSymbol(from text: String, fallback: String) -> String {
    // Try to find proper gene symbol patterns
    // Priority: uppercase letters with optional numbers (CRB1, IL2, BRCA1)
    
    let words = text.components(separatedBy: .whitespacesAndNewlines)
        .map { $0.trimmingCharacters(in: .punctuationCharacters) }
        .filter { !$0.isEmpty }
    
    // Look for uppercase gene symbols (CRB1, IL2, TNF, etc)
    for word in words {
        // Check if word is mostly uppercase and contains letters
        let uppercaseCount = word.filter { $0.isUppercase }.count
        let letterCount = word.filter { $0.isLetter }.count
        
        // Gene symbols are usually:
        // - Mostly uppercase (at least 50%)
        // - Between 2-10 characters
        // - May contain numbers (CRB1, IL2)
        if letterCount >= 2 && letterCount <= 10 &&
           uppercaseCount >= letterCount / 2 {
            return word
        }
    }
    
    // Fallback: first meaningful word
    if let firstWord = words.first, firstWord.count >= 2 {
        return firstWord
    }
    
    return fallback
}

// MARK: - Gene Models (임시 정의)

struct Gene: Identifiable, Codable, Hashable {
    let geneId: Int
    let symbol: String
    let name: String
    let organism: String
    let taxId: Int
    let chromosome: String
    let geneType: String
    let aliases: [String]
    let description: String?
    
    var id: Int { geneId }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(geneId)
    }
    
    static func == (lhs: Gene, rhs: Gene) -> Bool {
        return lhs.geneId == rhs.geneId
    }
}

enum GeneCategory: String, CaseIterable {
    case organism = "Organism"
    case geneType = "Gene Type"
    case chromosome = "Chromosome"
    case status = "Status"
    case symbolPrefix = "Symbol Prefix"
    
    var localizedName: String {
        switch self {
        case .organism: return LanguageHelper.string("gene_category_organism")
        case .geneType: return LanguageHelper.string("gene_category_gene_type")
        case .chromosome: return LanguageHelper.string("gene_category_chromosome")
        case .status: return LanguageHelper.string("gene_category_status")
        case .symbolPrefix: return LanguageHelper.string("gene_category_symbol_prefix")
        }
    }
}

enum GeneSubCategory: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }
    
    // Organism
    case homo_sapiens = "Homo sapiens"
    case mus_musculus = "Mus musculus"
    case drosophila_melanogaster = "Drosophila melanogaster"
    
    // Gene Type
    case protein_coding = "protein-coding"
    case miRNA = "miRNA"
    case lncRNA = "lncRNA"
    case pseudogene = "pseudogene"
    
    // Chromosome
    case chr1 = "1", chr2 = "2", chr3 = "3", chr4 = "4", chr5 = "5"
    case chr6 = "6", chr7 = "7", chr8 = "8", chr9 = "9", chr10 = "10"
    case chr11 = "11", chr12 = "12", chr13 = "13", chr14 = "14", chr15 = "15"
    case chr16 = "16", chr17 = "17", chr18 = "18", chr19 = "19", chr20 = "20"
    case chr21 = "21", chr22 = "22", chrX = "X", chrY = "Y", chrMT = "MT"
    
    // Status
    case live = "live"
    case discontinued = "discontinued"
    
    // Symbol Prefix
    case BRCA = "BRCA", HBA = "HBA", HBB = "HBB", TP = "TP", CFTR = "CFTR", HTT = "HTT"
    
    var parentCategory: GeneCategory {
        switch self {
        case .homo_sapiens, .mus_musculus, .drosophila_melanogaster:
            return .organism
        case .protein_coding, .miRNA, .lncRNA, .pseudogene:
            return .geneType
        case .chr1, .chr2, .chr3, .chr4, .chr5, .chr6, .chr7, .chr8, .chr9, .chr10,
             .chr11, .chr12, .chr13, .chr14, .chr15, .chr16, .chr17, .chr18, .chr19, .chr20,
             .chr21, .chr22, .chrX, .chrY, .chrMT:
            return .chromosome
        case .live, .discontinued:
            return .status
        case .BRCA, .HBA, .HBB, .TP, .CFTR, .HTT:
            return .symbolPrefix
        }
    }
}

// MARK: - NCBI API Response Models

struct ESearchResp: Decodable {
    struct ESearchResult: Decodable { 
        let idlist: [String]
        let webenv: String?
        let querykey: String?
        let count: String
    }
    let esearchresult: ESearchResult
}

struct GeneSummaryResp: Decodable { 
    let result: [String: GeneDoc] 
}

struct GeneDoc: Decodable {
    let uid: String
    let name: String?
    let description: String?
    let chromosome: String?
    let maplocation: String?
    let status: String?
    let nomenclaturename: String?
    let nomenclaturesymbol: String?
    let nomenclaturestatus: String?
    let genetype: String?
    let organism: Organism?
    let currentid: String?
    
    struct Organism: Decodable { 
        let scientificname: String?
        let taxid: Int?
    }
}

// MARK: - Gene Importer

@MainActor
class GeneImporter: ObservableObject {
    let base = URL(string: "https://eutils.ncbi.nlm.nih.gov/entrez/eutils")!
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMore = false
    @Published var totalCount: Int = 0
    @Published var totalCounts: [String: Int] = [:] // sub-category별 총 개수 저장
    
    private var currentCategory: GeneCategory?
    private var currentSubCategory: GeneSubCategory?
    private var currentOffset = 0
    private let pageSize = 100
    
    func esearch(term: String, organism: String, retmax: Int = 100, retstart: Int = 0) async throws -> (ids: [String], web: String?, q: String?, count: Int) {
        var comps = URLComponents(url: base.appendingPathComponent("esearch.fcgi"), resolvingAgainstBaseURL: false)!
        
        // organism이 비어있으면 term을 그대로 사용, 아니면 기존 로직 사용
        let finalTerm = organism.isEmpty ? term : "\(term) AND \(organism)[Organism]"
        
        comps.queryItems = [
            .init(name: "db", value: "gene"),
            .init(name: "term", value: finalTerm),
            .init(name: "retmode", value: "json"),
            .init(name: "retmax", value: "\(retmax)"),
            .init(name: "retstart", value: "\(retstart)"),
            .init(name: "usehistory", value: "y")
        ]
        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        let res = try JSONDecoder().decode(ESearchResp.self, from: data)
        let totalCount = Int(res.esearchresult.count) ?? 0
        return (res.esearchresult.idlist, res.esearchresult.webenv, res.esearchresult.querykey, totalCount)
    }
    
    func esummary(ids: [String]) async throws -> [GeneDoc] {
        guard !ids.isEmpty else { return [] }
        
        print("📊 esummary 호출: \(ids.count)개의 ID 요청")
        
        var comps = URLComponents(url: base.appendingPathComponent("esummary.fcgi"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            .init(name: "db", value: "gene"),
            .init(name: "id", value: ids.joined(separator: ",")),
            .init(name: "retmode", value: "json")
        ]
        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let result = json?["result"] as? [String: Any] else { 
            print("❌ result 파싱 실패")
            return [] 
        }
        
        print("📦 result keys: \(result.keys.count)개")
        
        // "uids" 배열을 제외한 실제 유전자 데이터만 수집
        var geneDocs: [GeneDoc] = []
        for (key, value) in result {
            if key != "uids", let geneData = value as? [String: Any] {
                // JSON을 GeneDoc으로 변환
                if let geneDoc = try? JSONDecoder().decode(GeneDoc.self, from: JSONSerialization.data(withJSONObject: geneData)) {
                    geneDocs.append(geneDoc)
                } else {
                    print("⚠️ GeneDoc 디코딩 실패: \(key)")
                }
            }
        }
        
        print("✅ esummary 결과: \(geneDocs.count)개의 GeneDoc 생성")
        return geneDocs
    }
    
    func normalize(_ docs: [GeneDoc]) -> [GeneDoc] {
        // uid를 기준으로 중복 제거 (currentid는 사용하지 않음)
        var byUid: [String: GeneDoc] = [:]
        for d in docs {
            if byUid[d.uid] == nil { 
                byUid[d.uid] = d 
                print("🔹 normalize: uid=\(d.uid), currentid=\(d.currentid ?? "nil")")
            }
        }
        print("🔄 normalize 완료: \(docs.count) -> \(byUid.values.count)")
        return Array(byUid.values)
    }
    
    // MARK: - Public Methods
    
    func searchGenes(category: GeneCategory, subCategory: GeneSubCategory, userSearchTerm: String? = nil) async throws -> [Gene] {
        // 새로운 검색이거나 검색어가 변경되면 offset 초기화
        if currentCategory != category || currentSubCategory != subCategory || userSearchTerm != nil {
            currentCategory = category
            currentSubCategory = subCategory
            currentOffset = 0
        }
        
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            var searchTerm = buildSearchTerm(category: category, subCategory: subCategory)
            
            // User search term이 있으면 추가
            if let userTerm = userSearchTerm, !userTerm.isEmpty {
                searchTerm = searchTerm.isEmpty ? userTerm : "\(searchTerm) AND \(userTerm)"
                print("🔍 User search term added: '\(userTerm)'")
            }
            
            // Organism을 검색어에 포함
            let organism = getOrganism(for: category, subCategory: subCategory)
            
            let finalSearchTerm: String
            if searchTerm.isEmpty {
                // Organism 카테고리인 경우 organism만 검색
                finalSearchTerm = "\(organism)[Organism]"
            } else if organism.isEmpty {
                // Organism이 없는 경우 검색어만 사용
                finalSearchTerm = searchTerm
            } else {
                // 둘 다 있는 경우 AND로 결합
                finalSearchTerm = "\(searchTerm) AND \(organism)[Organism]"
            }
            
            print("🔍 Search - Category: \(category.rawValue), SubCategory: \(subCategory.rawValue)")
            print("🔍 Final search term: \(finalSearchTerm)")
            
            let (ids, _, _, count) = try await esearch(term: finalSearchTerm, organism: "", retmax: pageSize, retstart: currentOffset)
            
            // 총 개수 저장 (첫 로드 시에만)
            if currentOffset == 0 {
                totalCount = count
                // sub-category별로 개수 저장
                let key = "\(category.rawValue)_\(subCategory.rawValue)"
                totalCounts[key] = count
                print("📊 Total genes found for \(subCategory.rawValue): \(count)")
            }
            
            // 더 가져올 데이터가 있는지 확인
            hasMore = (currentOffset + pageSize) < count
            
            guard !ids.isEmpty else {
                return []
            }
            
            let geneDocs = try await esummary(ids: ids)
            print("🔄 normalize 전: \(geneDocs.count)개")
            
            let normalizedDocs = normalize(geneDocs)
            print("🔄 normalize 후: \(normalizedDocs.count)개")
            
            // 다음 페이지를 위해 offset 증가
            currentOffset += pageSize
            
            let genes = normalizedDocs.compactMap { doc in
                convertToGene(doc)
            }
            print("✨ 최종 Gene 변환: \(genes.count)개")
            
            return genes
        } catch {
            errorMessage = "Failed to search genes: \(error.localizedDescription)"
            throw error
        }
    }
    
    func loadMoreGenes() async throws -> [Gene] {
        guard let category = currentCategory, let subCategory = currentSubCategory else {
            return []
        }
        
        return try await searchGenes(category: category, subCategory: subCategory)
    }
    
    func resetPagination() {
        currentOffset = 0
        hasMore = false
        totalCount = 0
        currentCategory = nil
        currentSubCategory = nil
        // totalCounts는 유지 (다른 sub-category의 개수 정보 보존)
    }
    
    func getTotalCount(category: GeneCategory, subCategory: GeneSubCategory) -> Int? {
        let key = "\(category.rawValue)_\(subCategory.rawValue)"
        return totalCounts[key]
    }
    
    private func buildSearchTerm(category: GeneCategory, subCategory: GeneSubCategory) -> String {
        switch category {
        case .organism:
            // Organism 카테고리의 경우 빈 검색어 반환 (organism은 getOrganism에서 처리)
            return ""
        case .geneType:
            return subCategory.rawValue
        case .chromosome:
            return "\(subCategory.rawValue)[chr]"
        case .status:
            return subCategory.rawValue
        case .symbolPrefix:
            return "\(subCategory.rawValue)*"
        }
    }
    
    private func getOrganism(for category: GeneCategory, subCategory: GeneSubCategory) -> String {
        // Organism 카테고리인 경우 sub-category 값을 organism으로 사용
        if category == .organism {
            return subCategory.rawValue
        }
        
        // 다른 카테고리인 경우 기본값으로 Homo sapiens 사용
        return "Homo sapiens"
    }
    
    private func convertToGene(_ doc: GeneDoc) -> Gene? {
        guard let uid = Int(doc.uid),
              let name = doc.name else {
            print("⚠️ convertToGene 실패: uid=\(doc.uid), name=\(doc.name ?? "nil")")
            return nil
        }
        
        // 심볼 추출: nomenclaturesymbol 우선, 없으면 더 똑똑하게 추출
        let symbol: String
        if let nomenclatureSymbol = doc.nomenclaturesymbol, !nomenclatureSymbol.isEmpty {
            // Use official gene symbol (e.g., "Shh", "Il2", "Cdkn1a", "CRB1")
            symbol = nomenclatureSymbol
        } else if let nomenclatureName = doc.nomenclaturename, !nomenclatureName.isEmpty {
            // Try to extract proper gene symbol from nomenclature name
            symbol = extractGeneSymbol(from: nomenclatureName, fallback: "GENE\(uid)")
        } else {
            // Try to extract from description
            symbol = extractGeneSymbol(from: name, fallback: "GENE\(uid)")
        }
        
        let gene = Gene(
            geneId: uid,
            symbol: symbol,
            name: name,
            organism: doc.organism?.scientificname ?? "Homo sapiens",
            taxId: doc.organism?.taxid ?? 9606,
            chromosome: doc.chromosome ?? "Unknown",
            geneType: doc.genetype ?? "unknown",
            aliases: [],
            description: doc.description
        )
        
        print("✅ Gene 생성 성공: \(symbol)")
        return gene
    }
}

// MARK: - Mock Data for Testing

extension GeneImporter {
    static func mockGenes(for subCategory: GeneSubCategory) -> [Gene] {
        let sampleGenes = [
            Gene(geneId: 7157, symbol: "TP53", name: "tumor protein p53", organism: "Homo sapiens", taxId: 9606, chromosome: "17", geneType: "protein-coding", aliases: ["P53"], description: "tumor protein p53 is a tumor suppressor gene..."),
            Gene(geneId: 672, symbol: "BRCA1", name: "BRCA1 DNA repair associated", organism: "Homo sapiens", taxId: 9606, chromosome: "17", geneType: "protein-coding", aliases: ["BRCC1"], description: "BRCA1 is a human tumor suppressor gene..."),
            Gene(geneId: 675, symbol: "BRCA2", name: "BRCA2 DNA repair associated", organism: "Homo sapiens", taxId: 9606, chromosome: "13", geneType: "protein-coding", aliases: ["BRCC2"], description: "BRCA2 is a human tumor suppressor gene..."),
            Gene(geneId: 1080, symbol: "CFTR", name: "CFTR transmembrane conductance regulator", organism: "Homo sapiens", taxId: 9606, chromosome: "7", geneType: "protein-coding", aliases: ["CF"], description: "CFTR is a chloride channel..."),
            Gene(geneId: 348, symbol: "APOE", name: "apolipoprotein E", organism: "Homo sapiens", taxId: 9606, chromosome: "19", geneType: "protein-coding", aliases: ["AD2"], description: "APOE is a major apoprotein...")
        ]
        
        switch subCategory {
        case .homo_sapiens:
            return Array(sampleGenes.prefix(10))
        case .protein_coding:
            return sampleGenes.filter { $0.geneType == "protein-coding" }
        case .chr17:
            return sampleGenes.filter { $0.chromosome == "17" }
        case .live:
            return sampleGenes
        case .BRCA:
            return sampleGenes.filter { $0.symbol.hasPrefix("BRCA") }
        default:
            return Array(sampleGenes.prefix(5))
        }
    }
}
