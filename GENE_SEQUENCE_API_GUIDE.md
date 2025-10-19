# Gene Library API 호출 가이드 - 그룹별 염기서열 데이터

## 📋 개요

DNAViewer의 Gene Library에서 gene을 선택하면 다음 프로세스로 염기서열 데이터를 가져옵니다:

1. **Gene 선택** → Gene ID 확보 (예: BRCA1 = 672)
2. **API 호출 1단계**: Gene ID → Nucleotide Accession 변환 (elink API)
3. **API 호출 2단계**: Nucleotide Accession → FASTA 염기서열 가져오기 (efetch API)
4. **그룹 생성**: 염기서열을 100bp씩 나누어 그룹 생성 (G1, G2, G3, ...)

---

## 🧬 주요 유전자 테스트 결과

### BRCA1 (Breast Cancer Gene)
**Gene ID**: 672  
**Accession**: NM_007294.4  
**염기서열 길이**: 7,088 bp  
**총 그룹 수**: 71 groups

```bash
# Step 1: Gene ID → Nucleotide Accession
curl "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=gene&db=nuccore&id=672&retmode=json"

# Step 2: Nucleotide Accession → 염기서열
curl "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=NM_007294.4&rettype=fasta&retmode=text"
```

**그룹 구성**:
- G1: 0-99 bp
- G2: 100-199 bp
- G3: 200-299 bp
- ...
- G71: 7000-7087 bp

**첫 100bp (G1)**:
```
GCTGAGACTTCCTGGACGGGGGACAGGCTGTGGGGTTTCTCAGATAACTGGGCCCCTGCGCTCAGGAGGC
CTTCACCCTCTGCTCTGGGTAAAGTTCATT
```

**염기 조성**:
- A: 2,368 (33.4%)
- T: 1,759 (24.8%)
- G: 1,585 (22.4%)
- C: 1,376 (19.4%)
- **GC Content**: 41.8%

---

### TP53 (Tumor Protein p53)
**Gene ID**: 7157  
**Accession**: NM_000546.6  
**염기서열 길이**: 2,512 bp  
**총 그룹 수**: 26 groups

```bash
# Step 1: Gene ID → Nucleotide Accession
curl "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=gene&db=nuccore&id=7157&retmode=json"

# Step 2: Nucleotide Accession → 염기서열
curl "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=NM_000546.6&rettype=fasta&retmode=text"
```

**첫 100bp (G1)**:
```
CTCAAAAGTCTAGAGCCACCGTCCAGGGAGCAGGTAGCTGCTGGGCTCCGGGGACACTTTGCGTTCGGGC
TGGGAGCGTGCTTTCCACGACGGTGACACG
```

**GC Content**: 53.4%

---

### CFTR (Cystic Fibrosis)
**Gene ID**: 1080  
**Accession**: NM_000492.4  
**염기서열 길이**: 6,070 bp  
**총 그룹 수**: 61 groups

```bash
# API 호출
curl "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=NM_000492.4&rettype=fasta&retmode=text"
```

**GC Content**: 40.9%

---

### APOE (Apolipoprotein E - Alzheimer's)
**Gene ID**: 348  
**Accession**: NM_000041.4  
**염기서열 길이**: 1,166 bp  
**총 그룹 수**: 12 groups

```bash
# API 호출
curl "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=NM_000041.4&rettype=fasta&retmode=text"
```

**GC Content**: 69.0%

---

### HBB (Hemoglobin Beta)
**Gene ID**: 3043  
**Accession**: NM_000518.5  
**염기서열 길이**: 626 bp  
**총 그룹 수**: 7 groups

```bash
# Gene ID → Nucleotide Accession
curl "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=gene&db=nuccore&id=3043&retmode=json"

# 염기서열 가져오기
curl "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=NM_000518.5&rettype=fasta&retmode=text"
```

---

## 🔍 그룹별 염기서열 표시 방식

메인화면으로 이동 후 **그룹(G1, G2, G3...)**이 나타나는 원리:

### DNASceneManager의 그룹 계산 로직

```swift
// 그룹 크기: 100bp
groupSize = 100

// 총 그룹 수 계산
totalGroups = (sequence.length + groupSize - 1) / groupSize

// 예: BRCA1 (7,088bp)
// totalGroups = (7088 + 99) / 100 = 71 groups

// 각 그룹의 범위
// G1:  displayStart = 0,    displayLength = 100  (0-99 bp)
// G2:  displayStart = 100,  displayLength = 100  (100-199 bp)
// G3:  displayStart = 200,  displayLength = 100  (200-299 bp)
// ...
// G71: displayStart = 7000, displayLength = 88   (7000-7087 bp)
```

### 그룹 선택 시 동작

1. 사용자가 **G3** 버튼 클릭
2. `loadGroup(3)` 호출
3. `displayStart = 200`, `displayLength = 100` 설정
4. sequence[200...299] 범위의 염기서열을 3D로 렌더링

---

## 📊 현재 코드의 문제점과 해결 방법

### ❌ 현재 LibraryView.swift의 문제

```swift
// 잘못된 API 호출
private func fetchGeneSequence(geneId: Int) async throws -> String {
    let urlString = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=gene&id=\(geneId)&rettype=fasta&retmode=text"
    // ❌ gene db는 sequence를 직접 제공하지 않음
}
```

### ✅ 올바른 방법

```swift
private func fetchGeneSequence(geneId: Int) async throws -> String {
    // Step 1: Gene ID → Nucleotide Accession 변환 (elink)
    let accessions = try await resolveAccessionsFromGeneUID(String(geneId))
    guard let firstAccession = accessions.first else {
        throw NSError(domain: "NoAccession", code: -1)
    }
    
    // Step 2: Nucleotide Accession → FASTA sequence (efetch)
    let urlString = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=\(firstAccession)&rettype=fasta&retmode=text"
    // ... URLSession으로 데이터 가져오기
}
```

### 추천: NCBIService 활용

```swift
// NCBIService.swift에 이미 구현된 메서드 활용
let accessions = try await NCBIService.shared.resolveAccessionsFromGeneUID(String(geneId))
let sequence = try await NCBIService.shared.fetchSequence(accession: accessions[0])
```

---

## 🚀 빠른 테스트 명령어

### 1. 여러 유전자 한 번에 테스트

```bash
for accession in NM_007294.4 NM_000546.6 NM_000492.4 NM_000041.4 NM_000518.5; do
  echo "=== $accession ==="
  curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=$accession&rettype=fasta&retmode=text" | head -5
  echo ""
done
```

### 2. 염기서열 길이 확인

```bash
# BRCA1 염기서열 길이 계산
curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=NM_007294.4&rettype=fasta&retmode=text" | grep -v "^>" | tr -d '\n' | wc -c
```

### 3. 특정 그룹의 염기서열 추출

```bash
# BRCA1의 G3 그룹 (200-299 bp) 추출
curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=NM_007294.4&rettype=fasta&retmode=text" | grep -v "^>" | tr -d '\n' | cut -c201-300
```

### 4. Python으로 전체 프로세스 자동화

```python
import subprocess

def get_gene_sequence(gene_id):
    # Step 1: Gene ID → Nucleotide Accession
    cmd1 = f'curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=gene&db=nuccore&id={gene_id}&retmode=json"'
    result1 = subprocess.run(cmd1, shell=True, capture_output=True, text=True)
    
    # JSON 파싱하여 accession 추출 (간단히 첫 번째 RefSeq mRNA 사용)
    # ... (실제 구현은 json.loads 사용)
    
    # Step 2: Accession → 염기서열
    accession = "NM_007294.4"  # 예시
    cmd2 = f'curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id={accession}&rettype=fasta&retmode=text"'
    result2 = subprocess.run(cmd2, shell=True, capture_output=True, text=True)
    
    # FASTA 파싱
    lines = result2.stdout.split('\n')
    sequence = ''.join(lines[1:])
    
    # 그룹 계산
    group_size = 100
    total_groups = (len(sequence) + group_size - 1) // group_size
    
    return {
        'accession': accession,
        'sequence': sequence,
        'length': len(sequence),
        'total_groups': total_groups
    }

# 사용 예
result = get_gene_sequence(672)  # BRCA1
print(f"Length: {result['length']} bp")
print(f"Groups: {result['total_groups']}")
```

---

## 📈 API 응답 형식

### elink API 응답 (JSON)

```json
{
  "linksets": [{
    "dbfrom": "gene",
    "ids": ["672"],
    "linksetdbs": [{
      "dbto": "nuccore",
      "linkname": "gene_nuccore_refseqrna",
      "links": ["1732746264", "2255456859", ...]
    }]
  }]
}
```

### efetch API 응답 (FASTA)

```
>NM_007294.4 Homo sapiens BRCA1 DNA repair associated (BRCA1), transcript variant 1, mRNA
GCTGAGACTTCCTGGACGGGGGACAGGCTGTGGGGTTTCTCAGATAACTGGGCCCCTGCGCTCAGGAGGC
CTTCACCCTCTGCTCTGGGTAAAGTTCATTGGAACAGAAAGAAATGGATTTATCTGCTCTTCGCGTTGAA
GAAGTACAAAATGTCATTAATGCTATGCAGAAAATCTTAGAGTGTCCCATCTGTCTGGAGTTGATCAAGG
...
```

---

## 🔧 Rate Limiting

NCBI API 제한:
- **기본**: 3 requests/second
- **API Key 등록 시**: 10 requests/second

### API Key 발급 및 사용

1. https://www.ncbi.nlm.nih.gov/account/settings/ 에서 발급
2. URL에 `&api_key=YOUR_KEY` 추가

```bash
curl "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=NM_007294.4&rettype=fasta&retmode=text&api_key=YOUR_API_KEY"
```

---

## 💡 유용한 팁

### 1. RefSeq vs GenBank

**RefSeq** (권장):
- 큐레이션된 고품질 데이터
- Accession 형식: `NM_`, `NR_`, `XM_`, `XR_`
- 예: `NM_007294.4`

**GenBank**:
- 연구자가 제출한 원본 데이터
- Accession 형식: 다양 (예: `AF087999`)

### 2. mRNA vs Genomic DNA

현재 코드는 **mRNA** 사용 (권장):
- 이유: Exon만 포함, 3D 표현에 적합
- Genomic DNA는 Intron 포함으로 너무 큼

### 3. 캐싱 전략

반복적인 API 호출 방지:
```swift
// CacheManager.swift 활용
if let cached = CacheManager.shared.getCachedSequence(accession: accession) {
    return cached
}
let sequence = try await NCBIService.shared.fetchSequence(accession: accession)
CacheManager.shared.cacheSequence(sequence, accession: accession)
```

---

## 🎯 테스트 체크리스트

- [x] BRCA1 (672) → NM_007294.4 → 7,088 bp
- [x] TP53 (7157) → NM_000546.6 → 2,512 bp
- [x] CFTR (1080) → NM_000492.4 → 6,070 bp
- [x] APOE (348) → NM_000041.4 → 1,166 bp
- [x] HBB (3043) → NM_000518.5 → 626 bp

---

## 📚 참고 문서

- **NCBI E-utilities**: https://www.ncbi.nlm.nih.gov/books/NBK25501/
- **ELink API**: https://www.ncbi.nlm.nih.gov/books/NBK25499/#chapter4.ELink
- **EFetch API**: https://www.ncbi.nlm.nih.gov/books/NBK25499/#chapter4.EFetch
- **RefSeq**: https://www.ncbi.nlm.nih.gov/refseq/
- **FASTA 형식**: https://en.wikipedia.org/wiki/FASTA_format

---

**작성일**: 2025-10-19  
**테스트 환경**: macOS, curl, Python 3, NCBI E-utilities API  
**앱 버전**: DNAViewer v1.0

