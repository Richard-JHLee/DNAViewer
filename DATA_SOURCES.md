# DNA Viewer - 데이터 소스 문서

## 📊 데이터 개요

DNA Viewer 앱은 현재 **로컬 데이터**를 사용하며, 실제 유전자 정보를 기반으로 한 샘플 시퀀스를 제공합니다.

---

## 🗂️ 데이터 위치

### 1. JSON 파일
**위치**: `Sources/Data/`

#### SampleGenes.json
**파일**: `Sources/Data/SampleGenes.json`  
**용도**: 유전자 라이브러리에 표시되는 샘플 유전자 정보  
**포맷**: JSON 배열

**포함된 유전자**:
- BRCA1 (NM_007294.4) - 445bp
- TP53 (NM_000546.6) - 393bp
- CFTR (NM_000492.4) - 1480bp
- HBB (NM_000518.5) - 444bp
- APOE (NM_000041.4) - 299bp

**데이터 구조**:
```json
{
  "id": "BRCA1",
  "name": "BRCA1",
  "accession": "NM_007294.4",
  "pdbID": null,
  "sequence": "ATGGATTTATCTGCTCTTCGCGTT...",
  "chromosome": "17q21.31",
  "startPos": 43044295,
  "endPos": 43125483,
  "strand": "minus",
  "geneType": "coding",
  "organism": "Homo sapiens",
  "features": [],
  "mutations": [
    {
      "id": "BRCA1_185delAG",
      "position": 185,
      "refBase": "AG",
      "altBase": "-",
      "type": "deletion",
      "consequence": "Frameshift",
      "clinicalSignificance": "pathogenic",
      "disease": "Breast and Ovarian Cancer",
      "description": "Common Ashkenazi Jewish founder mutation"
    }
  ],
  "summary": "DNA repair protein...",
  "diseaseLinks": ["Breast Cancer", "Ovarian Cancer"]
}
```

### 2. 하드코딩된 데이터
**위치**: `Sources/App/DNAViewModel.swift`

#### loadDefaultSequence()
**용도**: 앱 시작 시 기본으로 로드되는 BRCA1 시퀀스

**데이터**:
```swift
let sampleSequence = """
ATGGATTTATCTGCTCTTCGCGTTGAAGAAGTACAAAATGTCATTAATGCTATGCAGAAAATCTTAGAGTGTCCCATCTGTCTGGAGTTG
ATCAAGGAACCTGTCTCCACAAAGTGTGACCACATATTTTGCAAATTTTGCATGCTGAAACTTCTCAACCAGAAGAAAGGGCCTTCACA
GTGTCCTTTATGTAAGAATGATATAACCAAAAGGAGCCTACAAGAAAGTACGAGATTTAGTCAACTTGTTGAAGAGCTATTGAAAATCA
TTTGTGCTTTTCAGCTTGACACAGGTTTGGAGTATGCAAACAGCTATAATTTTGCAAAAAAGGAAAATAACTCTCCTGAACATCTAAAA
GATGAAGTTTCTATCATCCAAAGTATGGGCTACAGAAACCGTGCCAAAAGACTTCTACAGAGTGAACCCGAAAATCCTTCCTTGCAGGA
AACCAGTCTCAGTGTCCAACTCTCTAACCTTGGAACTGTGAGAACTCTGAGGACAAAGCAGCGGATACAACCTCAAAAGACGTCTGTCT
ACATTGAATTGGGATCTGATTCTTCTGAAGATACCGTTAATAAGGCAACTTATTGCAGTGTGGGAGATCAAGAATTGTTACAAATCACC
CCTCAAGGAACCAGGGATGAAATCAGTTTGGATTCTGCAAAAAAGGCTGCTTGTGAATTTTCTGAGACGGATGTAACAAATACTGAACA
TTAGTCCACGCAGTGCACTGCTCAGTCTAATTGTTGCAGCCTCTCCCCTTGGCTGATGCCATGCAGCACCTGTATTACGATAACCAGAA
CCAGTCCAGTGTTTAATGAGCTCTTCAAATAATGGCTAAGGCAGGGATGCCAGGCCTGGCCAATGAGCTGTTGCATCCTGCCAGGTAAA
"""
// 총 445bp
```

#### getSampleGeneSequences()
**용도**: LibraryView에서 유전자 선택 시 사용

**포함된 유전자**:
1. **BRCA1**: 273bp (샘플)
2. **TP53**: 273bp (샘플)
3. **CFTR**: 273bp (샘플)

---

## 🔬 실제 데이터 소스

### NCBI GenBank
**현재 상태**: 구현되어 있으나 미사용  
**파일**: `Sources/Services/NCBIService.swift`

**기능**:
```swift
class NCBIService {
    func fetchSequence(accession: String) async throws -> DNASequence
    func searchGene(name: String) async throws -> [SearchResult]
}
```

**API 엔드포인트**:
- E-utilities API: `https://eutils.ncbi.nlm.nih.gov/entrez/eutils/`
- efetch: 시퀀스 데이터 가져오기
- esearch: 유전자 검색

**예시**:
```
Accession: NM_007294.4 (BRCA1)
→ https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?
   db=nuccore&id=NM_007294.4&rettype=fasta&retmode=text
```

### PDB (Protein Data Bank)
**현재 상태**: 구현되어 있으나 미사용  
**파일**: `Sources/Services/PDBService.swift`

**기능**:
```swift
class PDBService {
    func fetchStructure(pdbID: String) async throws -> PDBStructure
}
```

**사용 예**:
- TP53: PDB ID `1TSR`
- CFTR: PDB ID `5UAK`
- APOE: PDB ID `1BZ4`

---

## 📂 데이터 흐름

### 앱 시작 시
```
ContentView.onAppear()
    ↓
DNAViewModel.loadDefaultSequence()
    ↓
하드코딩된 BRCA1 시퀀스 (445bp)
    ↓
DNASceneManager.loadSequence()
    ↓
3D 렌더링 (Group 1: 0~39bp)
```

### 라이브러리에서 유전자 선택
```
LibraryView
    ↓
loadSampleGenes()
    ↓
SampleGenes.json 로드 시도
    ↓
실패 시: loadDefaultGenes() (하드코딩)
    ↓
사용자가 유전자 선택 (예: TP53)
    ↓
createSequence(from: gene)
    ↓
ViewerView 표시
```

### 검색 시트 (향후 구현)
```
SearchSheet
    ↓
사용자 입력 (Accession 또는 Gene Name)
    ↓
NCBIService.fetchSequence() 또는 searchGene()
    ↓
실제 GenBank 데이터 가져오기
    ↓
ViewerView 표시
```

---

## 🎯 데이터 특징

### 실제 유전자 정보 기반
모든 시퀀스는 실제 인간 유전자의 일부입니다:

#### BRCA1 (Breast Cancer 1)
- **Accession**: NM_007294.4
- **염색체**: 17q21.31
- **크기**: 445bp (전체 유전자는 ~5,500bp)
- **기능**: DNA 복구, 종양 억제
- **질병**: 유방암, 난소암
- **유명 돌연변이**: 185delAG (Frameshift)

#### TP53 (Tumor Protein P53)
- **Accession**: NM_000546.6
- **PDB ID**: 1TSR
- **염색체**: 17p13.1
- **크기**: 393bp
- **기능**: 세포 주기 조절, 전사 인자
- **질병**: Li-Fraumeni 증후군, 다양한 암
- **유명 돌연변이**: R175H (DNA 결합 도메인)

#### CFTR (Cystic Fibrosis)
- **Accession**: NM_000492.4
- **PDB ID**: 5UAK
- **염색체**: 7q31.2
- **크기**: 1,480bp
- **기능**: 염소 이온 채널
- **질병**: 낭포성 섬유증
- **유명 돌연변이**: F508del (70% CF 환자)

#### HBB (Hemoglobin Beta)
- **Accession**: NM_000518.5
- **PDB ID**: 1HBS
- **염색체**: 11p15.4
- **크기**: 444bp
- **기능**: 산소 운반 (헤모글로빈 베타 사슬)
- **질병**: 겸상적혈구병, 베타-지중해빈혈
- **유명 돌연변이**: E6V (겸상적혈구)

#### APOE (Apolipoprotein E)
- **Accession**: NM_000041.4
- **PDB ID**: 1BZ4
- **염색체**: 19q13.32
- **크기**: 299bp
- **기능**: 콜레스테롤 대사
- **질병**: 알츠하이머병, 심혈관 질환
- **유명 변이**: E4 (알츠하이머 위험 증가)

---

## 🔄 데이터 로딩 방식

### 현재 구현 (로컬 데이터)

```swift
// 1. ContentView 초기화
DNAViewModel() → loadDefaultSequence()

// 2. 하드코딩된 BRCA1 시퀀스 사용
let sampleSequence = """
ATGGATTTATCTGCTCTTCGCGTTGAAGAAGTACAAAATGTCATTAAT...
"""

// 3. DNASequence 객체 생성
DNASequence(
    name: "BRCA1 (Breast Cancer Gene 1)",
    sequence: cleanedSequence,
    chromosome: "17",
    features: [...],
    mutations: [...]
)

// 4. 3D 렌더링
DNASceneManager.loadSequence(dnaSequence)
```

### 향후 구현 (API 데이터)

```swift
// 1. 사용자가 Accession 입력
searchSheet: "NM_007294.4"

// 2. NCBI API 호출
NCBIService.fetchSequence("NM_007294.4")
    ↓
https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?
  db=nuccore&id=NM_007294.4&rettype=fasta&retmode=text

// 3. FASTA 파싱
FASTAParser.parse(fastaString)
    ↓
DNASequence 객체 생성

// 4. 3D 렌더링
DNASceneManager.loadSequence(parsedSequence)
```

---

## 📋 데이터 필드 설명

### DNASequence
```swift
struct DNASequence {
    let id: UUID                    // 앱 내부 고유 ID
    let name: String                // "BRCA1 - Breast Cancer 1"
    let accession: String?          // GenBank ID (예: NM_007294.4)
    let pdbID: String?              // PDB ID (예: 1TSR)
    let sequence: String            // 실제 염기서열 "ATGC..."
    let chromosome: String?         // 염색체 위치 (예: "17q21.31")
    let startPos: Int?              // 염색체 상 시작 위치
    let endPos: Int?                // 염색체 상 종료 위치
    let strand: Strand              // Plus(+) 또는 Minus(-)
    let geneType: GeneType          // Coding, NonCoding, Regulatory
    let organism: String            // "Homo sapiens"
    var features: [GeneFeature]     // Exon, Intron, Promoter 등
    var mutations: [Mutation]       // 알려진 돌연변이
    let summary: String?            // 기능 설명
    let diseaseLinks: [String]?     // 관련 질병 목록
}
```

### GeneFeature
```swift
struct GeneFeature {
    let id: UUID
    let type: FeatureType           // exon, intron, promoter, enhancer, etc.
    let startIndex: Int             // 시퀀스 내 시작 위치
    let endIndex: Int               // 시퀀스 내 종료 위치
    let description: String?        // 기능 설명
}
```

### Mutation
```swift
struct Mutation {
    let id: UUID
    let position: Int               // 돌연변이 위치
    let refBase: String             // 원래 염기 (예: "A")
    let altBase: String             // 변이 염기 (예: "G")
    let type: MutationType          // snp, insertion, deletion, etc.
    let consequence: String?        // Missense, Frameshift, etc.
    let clinicalSignificance: ClinicalSignificance  // pathogenic, benign, etc.
    let disease: String?            // 관련 질병
    let description: String?        // 상세 설명
}
```

---

## 🌐 외부 API (구현됨, 미사용)

### NCBI E-utilities API
**베이스 URL**: `https://eutils.ncbi.nlm.nih.gov/entrez/eutils/`

#### EFetch (시퀀스 가져오기)
**엔드포인트**: `/efetch.fcgi`

**파라미터**:
- `db=nuccore`: 핵산 데이터베이스
- `id={accession}`: GenBank Accession (예: NM_007294.4)
- `rettype=fasta`: FASTA 포맷
- `retmode=text`: 텍스트 형식

**예시 요청**:
```
https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=NM_007294.4&rettype=fasta&retmode=text
```

**응답 예시**:
```fasta
>NM_007294.4 Homo sapiens BRCA1 DNA repair associated (BRCA1), mRNA
ATGGATTTATCTGCTCTTCGCGTTGAAGAAGTACAAAATGTCATTAATGCTATGCAGAAAATCTTAGAGT
GTCCCATCTGTCTGGAGTTGATCAAGGAACCTGTCTCCACAAAGTGTGACCACATATTTTGCAAATTTTG
...
```

#### ESearch (유전자 검색)
**엔드포인트**: `/esearch.fcgi`

**파라미터**:
- `db=gene`: 유전자 데이터베이스
- `term={gene name}`: 검색어 (예: BRCA1)
- `retmode=json`: JSON 형식

**예시 요청**:
```
https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=gene&term=BRCA1[Gene%20Name]+AND+Homo%20sapiens[Organism]&retmode=json
```

### PDB (Protein Data Bank)
**베이스 URL**: `https://files.rcsb.org/download/`

**파라미터**:
- PDB ID (예: 1TSR)
- 포맷: `.pdb` 파일

**예시 요청**:
```
https://files.rcsb.org/download/1TSR.pdb
```

**용도**:
- 단백질 3D 구조 데이터
- DNA-단백질 복합체 구조
- 향후 단백질 시각화 기능 확장

---

## 📥 데이터 파싱

### FASTAParser
**파일**: `Sources/Services/FASTAParser.swift`

**기능**:
```swift
class FASTAParser {
    static func parse(_ fastaString: String) -> DNASequence?
}
```

**FASTA 포맷**:
```fasta
>gi|568815597|ref|NM_007294.4| Homo sapiens BRCA1
ATGGATTTATCTGCTCTTCGCGTTGAAGAAGTACAAAATGTCATTAATGCTATGCAGAA
AATCTTAGAGTGTCCCATCTGTCTGGAGTTGATCAAGGAACCTGTCTCCACAAAGTGTG
```

**파싱 과정**:
1. 첫 줄 (`>...`): 메타데이터 추출
2. 나머지 줄: 염기서열 결합
3. 줄바꿈, 공백 제거
4. DNASequence 객체 생성

---

## 💾 캐시 관리

### CacheManager
**파일**: `Sources/Services/CacheManager.swift`

**기능**:
```swift
class CacheManager {
    static let shared = CacheManager()
    
    func saveSequence(_ sequence: DNASequence)
    func loadSequence(id: String) -> DNASequence?
    func loadRecentItems() -> [RecentItem]
    func clearCache()
}
```

**저장 위치**:
- UserDefaults: 최근 항목 목록
- FileManager: 시퀀스 데이터 (향후 구현)

---

## 🔮 향후 데이터 확장 계획

### 1. 실시간 API 통합
```swift
// SearchSheet에서 사용자 입력
"BRCA1" 입력
    ↓
NCBIService.searchGene("BRCA1")
    ↓
검색 결과 표시
    ↓
사용자 선택
    ↓
NCBIService.fetchSequence("NM_007294.4")
    ↓
실제 GenBank 데이터 로드
    ↓
3D 렌더링
```

### 2. 더 많은 유전자
**계획**:
- 현재: 5개 유전자 (BRCA1, TP53, CFTR, HBB, APOE)
- 목표: 100+ 주요 인간 유전자
- 소스: SampleGenes.json 확장

### 3. 사용자 데이터
**기능**:
- 커스텀 시퀀스 입력
- FASTA 파일 업로드
- Pasteboard에서 시퀀스 붙여넣기

### 4. 데이터베이스 통합
**옵션**:
- Ensembl API
- UCSC Genome Browser
- NCBI RefSeq
- UniProt (단백질 정보)

---

## 📊 데이터 통계

### 현재 포함된 데이터

**유전자 수**: 5개  
**총 염기쌍**: ~3,061bp

| 유전자 | Accession | 크기 | 염색체 | 질병 |
|--------|-----------|------|--------|------|
| BRCA1 | NM_007294.4 | 445bp | 17q21.31 | 유방암, 난소암 |
| TP53 | NM_000546.6 | 393bp | 17p13.1 | Li-Fraumeni, 암 |
| CFTR | NM_000492.4 | 1,480bp | 7q31.2 | 낭포성 섬유증 |
| HBB | NM_000518.5 | 444bp | 11p15.4 | 겸상적혈구병 |
| APOE | NM_000041.4 | 299bp | 19q13.32 | 알츠하이머 |

### 돌연변이 데이터
**총 돌연변이**: 5개 (각 유전자당 1개씩)

**타입**:
- SNP (Single Nucleotide Polymorphism): 3개
- Deletion: 2개

**임상 의미**:
- Pathogenic: 4개
- Likely Pathogenic: 1개

---

## 🔐 데이터 출처 및 신뢰성

### GenBank (NCBI)
- **신뢰도**: ⭐⭐⭐⭐⭐ (공식 유전체 데이터베이스)
- **업데이트**: 주기적
- **검증**: Peer-reviewed
- **라이선스**: Public Domain

### PDB (Protein Data Bank)
- **신뢰도**: ⭐⭐⭐⭐⭐ (공식 단백질 구조 데이터베이스)
- **검증**: X-ray crystallography, NMR, Cryo-EM
- **라이선스**: Public Domain

### 앱 내 샘플 데이터
- **출처**: NCBI GenBank 기반 추출
- **검증**: 실제 유전자 시퀀스의 일부
- **목적**: 교육 및 데모용
- **주의**: 전체 유전자가 아닌 부분 시퀀스

---

## ⚠️ 면책 조항

**교육 목적**: 이 앱의 데이터는 교육 및 학습 목적으로만 사용해야 합니다.

**의료 진단 금지**: 임상 진단이나 의료 결정에 사용하지 마십시오.

**데이터 정확성**: 샘플 데이터는 실제 유전자의 일부이지만, 전체 유전자를 대표하지 않습니다.

**최신 정보**: 최신 유전자 정보는 NCBI GenBank 또는 전문 데이터베이스를 참조하세요.

---

## 📚 참고 자료

### 데이터베이스
- **NCBI GenBank**: https://www.ncbi.nlm.nih.gov/genbank/
- **PDB**: https://www.rcsb.org/
- **Ensembl**: https://www.ensembl.org/
- **UCSC Genome Browser**: https://genome.ucsc.edu/

### API 문서
- **NCBI E-utilities**: https://www.ncbi.nlm.nih.gov/books/NBK25501/
- **PDB API**: https://www.rcsb.org/docs/programmatic-access

### 유전자 정보
- **GeneCards**: https://www.genecards.org/
- **OMIM**: https://www.omim.org/
- **ClinVar**: https://www.ncbi.nlm.nih.gov/clinvar/

---

**마지막 업데이트**: 2025-10-18  
**데이터 버전**: 1.0.0

