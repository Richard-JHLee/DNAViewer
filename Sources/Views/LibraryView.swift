//
//  LibraryView.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-17.
//

import SwiftUI

struct LibraryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: DNAViewModel
    @StateObject private var geneImporter = GeneImporter()
    @State private var selectedCategory: GeneCategory?
    @State private var selectedSubCategory: GeneSubCategory?
    @State private var selectedGeneForDetail: Gene? // sheet(item:)용으로 변경
    @State private var genes: [Gene] = []
    @State private var useMockData = false // 실제 API 데이터 사용
    @State private var searchText: String = ""
    @State private var searchTask: Task<Void, Never>? // For debouncing
    @State private var isSearching: Bool = false
    @State private var originalGenes: [Gene] = [] // Backup for restoring after search
    
    // No need for local filtering - we'll use API search
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Search Bar (shown when gene list is visible)
                if selectedSubCategory != nil {
                    searchBar
                }
                
                // Content
                if selectedCategory == nil {
                    categoryGridView
                } else if selectedSubCategory == nil {
                    subCategoryView
                } else {
                    geneListView
                }
            }
            .navigationTitle("Gene Library")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .onChange(of: searchText) { newValue in
                // Cancel previous search task
                searchTask?.cancel()
                
                // Debounce: wait 0.5 seconds before searching
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    
                    guard !Task.isCancelled else { return }
                    
                    await performSearch(newValue)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedCategory != nil || selectedSubCategory != nil {
                        Button("Back") {
                            if selectedSubCategory != nil {
                                selectedSubCategory = nil
                                searchText = ""  // Clear search when going back
                                originalGenes = []  // Clear backup
                                searchTask?.cancel()  // Cancel any pending search
                            } else {
                                selectedCategory = nil
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedGeneForDetail) { gene in
            // Gene 상세 정보 화면
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                                Text(gene.symbol.isEmpty ? "Unknown Gene" : gene.symbol)
                                    .font(.system(size: 34, weight: .bold))
                                    .onAppear {
                                        print("🔍 Gene Detail: symbol='\(gene.symbol)', name='\(gene.name)'")
                                    }
                                
                                Text(gene.name)
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Label("ID: \(gene.geneId)", systemImage: "number")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text(gene.organism)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                            .padding()
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(12)
                            
                            Divider()
                            
                            // Basic Information
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Basic Information")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                GeneInfoRow(icon: "tag", title: "Gene ID", value: "\(gene.geneId)")
                                GeneInfoRow(icon: "person.3", title: "Organism", value: gene.organism)
                                GeneInfoRow(icon: "map", title: "Chromosome", value: gene.chromosome)
                                GeneInfoRow(icon: "function", title: "Gene Type", value: gene.geneType)
                                GeneInfoRow(icon: "number", title: "Tax ID", value: "\(gene.taxId)")
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)
                            
                            // Description
                            if let description = gene.description {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Description")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Text(description)
                                        .font(.body)
                                    .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(12)
                            }
                            
                            // Aliases (if any)
                            if !gene.aliases.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Aliases")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    SimpleFlowLayout(spacing: 8) {
                                        ForEach(gene.aliases, id: \.self) { alias in
                                            Text(alias)
                                                .font(.caption)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(Color.green.opacity(0.2))
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(12)
                            }
                    }
                    .padding()
                }
                .navigationTitle("Gene Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            selectedGeneForDetail = nil
                        }
                    }
                }
            }
        }
    }
    // MARK: - Search Logic
    private func performSearch(_ searchTerm: String) async {
        guard let category = selectedCategory,
              let subCategory = selectedSubCategory else { return }
        
        // Save original genes on first search
        if originalGenes.isEmpty && !genes.isEmpty {
            originalGenes = genes
        }
        
        if searchTerm.isEmpty {
            // Restore original genes when search is cleared
            genes = originalGenes
            isSearching = false
            return
        }
        
        // Perform API search
        isSearching = true
        
        do {
            print("🔍 Performing API search: '\(searchTerm)' in \(subCategory.rawValue)")
            let searchResults = try await geneImporter.searchGenes(
                category: category,
                subCategory: subCategory,
                userSearchTerm: searchTerm
            )
            
            await MainActor.run {
                genes = searchResults
                isSearching = false
                print("✅ Search complete: found \(searchResults.count) genes")
            }
        } catch {
            await MainActor.run {
                isSearching = false
                print("❌ Search failed: \(error)")
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search genes by name, symbol, or chromosome...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("DNA Atlas")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            if let category = selectedCategory {
                Text(category.localizedName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let subCategory = selectedSubCategory {
                Text(subCategory.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
    }
    
    private var categoryGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
            ForEach(GeneCategory.allCases, id: \.self) { category in
                CategoryCard(
                    title: category.localizedName,
                    subtitle: category.rawValue,
                    icon: iconForCategory(category)
                ) {
                        selectedCategory = category
                    }
                }
            }
            .padding()
        }
    }
    
    private var subCategoryView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if let category = selectedCategory {
                    ForEach(subCategoriesForCategory(category), id: \.self) { subCategory in
                        SubCategoryRow(
                            title: subCategory.rawValue,
                            count: getTotalCount(for: subCategory),
                            isLoading: isLoadingSubCategory(subCategory)
                        ) {
                            selectedSubCategory = subCategory
                            loadGenes(for: subCategory)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var geneListView: some View {
        VStack {
            if genes.isEmpty && geneImporter.isLoading {
                ProgressView("Loading genes...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = geneImporter.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Error loading genes")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Show search status
                        if isSearching {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Searching...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        } else if !searchText.isEmpty {
                            HStack {
                                Text("Found \(genes.count) gene(s)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        
                        ForEach(genes) { gene in
                            GeneCard(gene: gene, onInfoTap: {
                                selectedGeneForDetail = gene
                            }, onApply: {
                                applyGeneToMainView(gene)
                            })
                        }
                        
                        // Load More 버튼 (검색 중이 아닐 때만 표시)
                        if geneImporter.hasMore && searchText.isEmpty {
                            Button {
                                Task {
                                    do {
                                        let moreGenes = try await geneImporter.loadMoreGenes()
                                        genes.append(contentsOf: moreGenes)
                                    } catch {
                                        print("Failed to load more genes: \(error)")
                                    }
                                }
                            } label: {
                                HStack {
                                    if geneImporter.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                    } else {
                                        Text("Load More")
                                            .font(.headline)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                            .disabled(geneImporter.isLoading)
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func iconForCategory(_ category: GeneCategory) -> String {
        switch category {
        case .organism:
            return "figure.2.and.child.holdinghands"
        case .geneType:
            return "function"
        case .chromosome:
            return "circle.grid.3x3"
        case .status:
            return "checkmark.circle"
        case .symbolPrefix:
            return "textformat.abc"
        }
    }
    
    private func subCategoriesForCategory(_ category: GeneCategory) -> [GeneSubCategory] {
        return GeneSubCategory.allCases.filter { $0.parentCategory == category }
    }
    
    private func getTotalCount(for subCategory: GeneSubCategory) -> Int? {
        // 해당 sub-category의 실제 개수가 있으면 반환
        if let category = selectedCategory,
           let actualCount = geneImporter.getTotalCount(category: category, subCategory: subCategory) {
            return actualCount
        }
        
        // 로딩 중이면 nil 반환
        if isLoadingSubCategory(subCategory) {
            return nil
        }
        
        // 아직 로드되지 않았으면 nil 반환 (Tap to load 표시)
        return nil
    }
    
    private func isLoadingSubCategory(_ subCategory: GeneSubCategory) -> Bool {
        // 현재 선택된 sub-category이고, 로딩 중이며, 아직 totalCount가 없는 경우
        return selectedSubCategory == subCategory && 
               geneImporter.isLoading && 
               (selectedCategory == nil || geneImporter.getTotalCount(category: selectedCategory!, subCategory: subCategory) == nil)
    }
    
    private func mockCountForSubCategory(_ subCategory: GeneSubCategory) -> Int {
        switch subCategory {
        case .homo_sapiens:
            return 25000
        case .mus_musculus:
            return 23000
        case .drosophila_melanogaster:
            return 15000
        case .protein_coding:
            return 20000
        case .miRNA:
            return 2000
        case .lncRNA:
            return 15000
        case .pseudogene:
            return 8000
        case .chr1, .chr2, .chr3, .chr4, .chr5, .chr6, .chr7, .chr8, .chr9, .chr10,
             .chr11, .chr12, .chr13, .chr14, .chr15, .chr16, .chr17, .chr18, .chr19, .chr20,
             .chr21, .chr22, .chrX, .chrY, .chrMT:
            return Int.random(in: 500...2000)
        case .live:
            return 20000
        case .discontinued:
            return 500
        case .BRCA, .HBA, .HBB, .TP, .CFTR, .HTT:
            return Int.random(in: 10...100)
        }
    }
    
    private func loadGenes(for subCategory: GeneSubCategory) {
        Task {
            do {
                // 새로운 검색이므로 기존 genes 초기화
                genes = []
                originalGenes = []  // Clear backup when loading new category
                searchText = ""  // Clear search
                geneImporter.resetPagination()
                
                if useMockData {
                    // Mock 데이터 사용
                    genes = GeneImporter.mockGenes(for: subCategory)
                } else {
                    // 실제 API 호출 (첫 100개)
                    guard let category = selectedCategory else { return }
                    genes = try await geneImporter.searchGenes(category: category, subCategory: subCategory)
                }
            } catch {
                print("Error loading genes: \(error)")
            }
        }
    }
    
    private func applyGeneToMainView(_ gene: Gene) {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔄 Applying gene to main view")
        print("   Gene Symbol: \(gene.symbol)")
        print("   Gene ID: \(gene.geneId)")
        print("   Chromosome: \(gene.chromosome)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        Task {
            do {
                // NCBI API를 통해 gene sequence 가져오기
                let sequence = try await fetchGeneSequence(geneId: gene.geneId)
                
                await MainActor.run {
                    // Use symbol, fallback to first word of name if symbol is empty
                    let geneName: String
                    if !gene.symbol.isEmpty && gene.symbol != "GENE\(gene.geneId)" {
                        geneName = gene.symbol
                    } else {
                        // Extract first meaningful word from name
                        geneName = gene.name.components(separatedBy: .whitespaces).first ?? "Gene\(gene.geneId)"
                    }
                    
                    // DNASequence 생성
                    let dnaSequence = DNASequence(
                        name: geneName,
                        sequence: sequence,
                        chromosome: gene.chromosome,
                        organism: gene.organism,
                        summary: gene.description
                    )
                    
                    print("📦 Created DNASequence:")
                    print("   Gene Symbol: \(gene.symbol)")
                    print("   Gene Name (full): \(gene.name)")
                    print("   DNASequence Name: \(dnaSequence.name)")
                    print("   ID: \(dnaSequence.id)")
                    print("   Length: \(dnaSequence.length) bp")
                    
                    // 그룹 수 계산 미리보기
                    let groupSize = 100
                    let totalGroups = (dnaSequence.length + groupSize - 1) / groupSize
                    print("   Expected Groups: \(totalGroups)")
                    
                    // ViewModel에 적용
                    print("🔄 Setting viewModel.currentSequence...")
                    viewModel.currentSequence = dnaSequence
                    viewModel.currentSequenceName = dnaSequence.name
                    
                    print("✅ Gene applied successfully!")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    
                    // Library sheet 닫기
                    dismiss()
                }
            } catch {
                print("❌ Failed to fetch gene sequence: \(error)")
                print("⚠️ Falling back to sample sequence...")
                
                // 샘플 시퀀스로 대체
                await MainActor.run {
                    // Use symbol, fallback to first word of name if symbol is empty
                    let geneName: String
                    if !gene.symbol.isEmpty && gene.symbol != "GENE\(gene.geneId)" {
                        geneName = gene.symbol
                    } else {
                        // Extract first meaningful word from name
                        geneName = gene.name.components(separatedBy: .whitespaces).first ?? "Gene\(gene.geneId)"
                    }
                    
                    let sampleSequence = generateSampleSequence(length: 1000)
                    let dnaSequence = DNASequence(
                        name: geneName,
                        sequence: sampleSequence,
                        chromosome: gene.chromosome,
                        organism: gene.organism,
                        summary: gene.description
                    )
                    
                    print("📦 Created sample DNASequence:")
                    print("   Gene Symbol: \(gene.symbol)")
                    print("   DNASequence Name: \(dnaSequence.name)")
                    print("   Length: \(dnaSequence.length) bp")
                    
                    viewModel.currentSequence = dnaSequence
                    viewModel.currentSequenceName = dnaSequence.name
                    print("✅ Sample sequence applied")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    dismiss()
                }
            }
        }
    }
    
    private func fetchGeneSequence(geneId: Int) async throws -> String {
        print("🔍 fetchGeneSequence: Gene ID = \(geneId)")
        
        // Step 1: Gene ID → Nucleotide Accession 변환 (elink API)
        let accessions = try await NCBIService.shared.resolveAccessionsFromGeneUID(String(geneId), retmax: 1)
        
        guard let firstAccession = accessions.first else {
            print("❌ No nucleotide accession found for gene ID: \(geneId)")
            throw NSError(domain: "GeneSequence", code: -1, userInfo: [NSLocalizedDescriptionKey: "No nucleotide accession found"])
        }
        
        print("✅ Found accession: \(firstAccession)")
        
        // Step 2: Nucleotide Accession → FASTA sequence (efetch API)
        let urlString = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=\(firstAccession)&rettype=fasta&retmode=text"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        print("📡 Fetching sequence from: \(urlString)")
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // FASTA 형식 파싱
        if let text = String(data: data, encoding: .utf8) {
            // '>'로 시작하는 헤더 라인 제거하고 시퀀스만 추출
            let lines = text.components(separatedBy: .newlines)
            let sequenceLines = lines.filter { !$0.hasPrefix(">") && !$0.isEmpty }
            let sequence = sequenceLines.joined().uppercased()
            
            print("✅ Sequence length: \(sequence.count) bp")
            
            if !sequence.isEmpty {
                return sequence
            }
        }
        
        throw NSError(domain: "GeneSequence", code: -1, userInfo: [NSLocalizedDescriptionKey: "No sequence found"])
    }
    
    private func generateSampleSequence(length: Int) -> String {
        let bases = ["A", "T", "G", "C"]
        return (0..<length).map { _ in bases.randomElement()! }.joined()
    }
}

// MARK: - Supporting Views

struct CategoryCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SubCategoryRow: View {
    let title: String
    let count: Int?  // Optional로 변경
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 6) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 12, height: 12)
                            Text("Loading...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if let count = count {
                            Text("\(formatNumber(count)) genes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Tap to load")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

struct GeneCard: View {
    let gene: Gene
    let onInfoTap: () -> Void
    let onApply: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(gene.symbol)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("ID: \(gene.geneId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                    
                    Spacer()
                }
                
                Text(gene.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let description = gene.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                HStack {
                    Spacer()
                    
                    // Info 버튼 (상세 정보)
                    Button(action: onInfoTap) {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle")
                            Text("Info")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Apply 버튼
                    Button(action: onApply) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Apply")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                }
                .padding(.top, 4)
                }
            }
            .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Helper Views

struct GeneInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// iOS 15.0 호환 FlowLayout (VStack/HStack로 대체)
struct SimpleFlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content
    
    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        // 간단히 HStack으로 표시
        HStack(spacing: spacing) {
            content()
        }
    }
}

#Preview {
    LibraryView(viewModel: DNAViewModel())
}