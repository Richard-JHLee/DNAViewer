# DNA_VIEWER_SPEC.md
절대 기존 기능을 없애지 말것, 없앨 경우 승인 받고 할것
build 할때 platform 은 macOS로 할것
소스 작성시 구조체 소스 수정 시 열고 닫는 위치를 확인 후 수정할것
교육용 **DNA Viewer** 앱을 "네이티브 Swift만으로" 자동 개발(Copilot/Cursor Auto)하기 위한 **단일 설계 문서**입니다.  
목표: 백엔드 없이도 공개 유전체 데이터베이스에서 직접 DNA 서열과 구조를 내려받아 **이중나선 구조 시각화 + 유전 정보 학습 기능**을 제공합니다.

---

## 0. 디자인 결정(의견)
- **렌더링**: SceneKit 기반(추후 Metal로 확장). 1차 릴리스에서는 **Double Helix/Ball-and-Stick/Ladder** 중심.
- **데이터 소스(백엔드 없음)**:  
  - NCBI GenBank: `https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id={ACCESSION}&rettype=fasta`
  - PDB DNA 구조: `https://files.rcsb.org/download/{PDB_ID}.cif`
  - 샘플 유전자 데이터 내장(BRCA1, TP53, CFTR 등)
- **염기쌍 정보**: Watson-Crick 염기쌍 규칙(A-T, G-C)으로 온디바이스 생성
- **교육성 강화**: "DNA 구조 설명/유전자 코드 번역/돌연변이 시뮬레이션/질병 연관성"을 필수로 포함
- **성능**: 긴 서열(>100k bp)은 **개요 뷰 + 상세 구간 선택** 기본

---

## 1. 범위
### 1.1 기능(요구 사항)
- **기본 뷰어**
  - 회전/확대/축소, 구간 선택(Sequence Range Selector)
  - 표현: Double Helix(이중나선), Ladder(사다리형), Ball-and-Stick, Sequence Only(서열만)
  - 색상: By Base(염기별: A=빨강, T=파랑, G=녹색, C=노랑), By Strand, Uniform, GC Content(GC 함량)
  - **구조 단계별 보기**: 
    - Primary(1차): 염기서열 텍스트/바 차트
    - Secondary(2차): 이중나선 3D 구조
    - Tertiary(3차): 슈퍼코일링, 뉴클레오솜 구조
    - Chromosome(염색체): 염색체 수준 패키징

- **유전 정보 학습**
  - 설명 모드(초·중·고 / 대학·전문가 2레벨)
  - 염기서열 → 아미노산 번역(코돈표 시각화)
  - 유전자 구조: Promoter, Exon, Intron, 3'/5' UTR 하이라이트
  - 돌연변이 시뮬레이터: Point mutation, Insertion, Deletion, Inversion
  - 퀴즈(객관식/주관식) + 피드백

- **생물학적 맥락**
  - 대표 유전자 10종 카드:
    - BRCA1/BRCA2(유방암)
    - TP53(종양억제)
    - CFTR(낭포성 섬유증)
    - HBB(겸상적혈구)
    - APOE(알츠하이머)
    - INS(인슐린)
    - DMD(근이영양증)
    - HTT(헌팅턴병)
    - F8(혈우병)
    - MTHFR(엽산대사)
  - 각 유전자의 기능, 질병 연관성, 대표 돌연변이 위치 표시

- **DNA 분석 도구**
  - GC 함량 계산 및 그래프
  - CpG Island 찾기
  - Restriction site(제한효소 인식 서열) 검색
  - ORF(Open Reading Frame) 찾기
  - 상보적 서열(Complementary) 생성
  - Reverse Complement 생성

- **데이터 연동**
  - GenBank Accession 입력 → FASTA 다운로드/캐시
  - PDB ID 입력 → DNA 구조 다운로드
  - 로컬 FASTA 파일 불러오기
  - 사용자 정의 서열 입력(수동)

- **확장 기능**
  - AR 모드(선택, RealityKit로 이중나선을 실제 공간에 배치)
  - 복제(Replication), 전사(Transcription), 번역(Translation) 애니메이션
  - DNA 지문 분석(STR/Microsatellite 마커)
  - 다국어(영/한 우선), 학습 진도 로컬 저장
  - 비교 뷰어(두 서열 Alignment 시각화)

### 1.2 비범위(1차 릴리스에서 제외)
- 전체 게놈 브라우저(Genome Browser)
- NGS 데이터 분석
- Phylogenetic tree 생성
- 클라우드 동기화/공유 기능
- 교사용 대시보드

---

## 2. 화면/플로우
### 2.1 네비게이션
- **HomeView** → **ViewerView** → (InfoSheet / QuizSheet / TranslationSheet / MutationSheet)
- **SearchSheet**: GenBank Accession/PDB ID 입력 → 다운로드 → ViewerView 로드
- **LibraryView**: 대표 유전자 10종 카드 갤러리

### 2.2 주요 화면 구성
- **HomeView**
  - 상단: 앱 제목(DNA Viewer)
  - 카드 섹션: "대표 유전자 탐색", "새로운 서열 불러오기", "학습 모드"
  - 최근 본 DNA 목록(썸네일)

- **ViewerView**
  - 상단: 제목(유전자명/Accession), "+"(불러오기), "i"(정보), "🧬"(번역), "⚡️"(돌연변이)
  - 중앙: **SCNView**(SceneKit) - 3D DNA 구조
  - 우측 부동 버튼: 
    - ▶︎(구조 애니메이션: 회전/언와인딩)
    - ⓘ(설명 모드)
    - 🔬(분석 도구)
  - 하단 **ControlBar**(10개 버튼):
    - 표현: Double Helix / Ladder / Ball-Stick / Sequence
    - 색상: By Base / By Strand / Uniform / GC Content
    - 도구: Zoom to Region / Measure
  - **SequenceBar**(토글 가능):
    - 염기서열 스크롤뷰(가로 스크롤, 10bp 단위 눈금)
    - 탭하면 해당 위치로 3D 뷰 이동/하이라이트
    - 색상 코딩: A(빨강), T(파랑), G(녹색), C(노랑)
    - 상보적 가닥도 함께 표시(옵션)

- **InfoSheet**
  - 유전자명 및 공식 심볼
  - 염색체 위치(예: 17q21.31)
  - 기능 요약(100자 이내)
  - 서열 길이, GC 함량
  - 관련 질병/형질
  - 외부 링크: NCBI Gene, OMIM, GeneCards

- **TranslationSheet**(번역 도구)
  - 6-frame translation 표시
  - ORF 하이라이트
  - Start codon(ATG), Stop codon(TAA/TAG/TGA) 마킹
  - 코돈표 참조 패널
  - 번역된 아미노산 서열 표시

- **MutationSheet**(돌연변이 시뮬레이터)
  - 돌연변이 타입 선택: Point / Insertion / Deletion / Inversion
  - 위치 선택(서열바에서 선택 또는 직접 입력)
  - 변경 전/후 서열 비교
  - 아미노산 변화 표시(Synonymous/Missense/Nonsense/Frameshift)
  - 알려진 질병 돌연변이 예시 로드

- **QuizSheet**
  - 문제 유형:
    - "이 염기의 상보적 염기는?"
    - "이 코돈이 코딩하는 아미노산은?"
    - "GC 함량이 높은 구간은?"
    - "이 유전자의 주요 기능은?"
  - 답 선택 → 정답 하이라이트(3D 뷰에서도 표시)
  - 해설 및 추가 학습 자료 링크

- **AnalysisSheet**(분석 도구)
  - GC Content Plot(그래프)
  - Restriction Sites(제한효소 사이트 표)
  - CpG Islands(CpG 섬 위치)
  - Motif Search(특정 서열 패턴 검색)
  - Export 기능(FASTA, 이미지)

---

## 3. 데이터 모델
### 3.1 핵심 구조체
```swift
struct DNASequence: Identifiable, Codable {
    let id: UUID
    let name: String           // 유전자명 또는 설명
    let accession: String?     // GenBank Accession
    let pdbID: String?         // PDB ID (구조 데이터)
    let sequence: String       // 염기서열 (ATGC)
    let chromosome: String?    // 염색체 위치
    let startPos: Int?
    let endPos: Int?
    let strand: Strand         // Plus(+) / Minus(-)
    let geneType: GeneType     // Coding / NonCoding / Regulatory
    let organism: String       // Homo sapiens, etc.
    var features: [GeneFeature] // Exon, Intron, Promoter 등
    var mutations: [Mutation]   // 알려진 돌연변이
    let summary: String?        // 기능 요약
    let diseaseLinks: [String]? // 관련 질병
}

enum Strand: String, Codable {
    case plus, minus
}

enum GeneType: String, Codable {
    case coding, nonCoding, regulatory, intergenic
}

struct GeneFeature: Identifiable, Codable {
    let id: UUID
    let type: FeatureType
    let range: Range<Int>  // 서열 내 위치
    let label: String?
}

enum FeatureType: String, Codable {
    case promoter, exon, intron, utr5, utr3, cds, polyA
}

struct Mutation: Identifiable, Codable {
    let id: UUID
    let position: Int
    let refBase: String    // Reference base
    let altBase: String    // Alternative base
    let type: MutationType
    let consequence: String // Missense, Nonsense, etc.
    let clinicalSignificance: String? // Pathogenic, Benign, etc.
    let disease: String?
}

enum MutationType: String, Codable {
    case snp, insertion, deletion, inversion, duplication
}

struct Codon {
    let sequence: String // 3-letter (e.g., "ATG")
    let aminoAcid: String // 1-letter (e.g., "M")
    let fullName: String // "Methionine"
}
```

### 3.2 3D 렌더링 모델
```swift
class DNASceneManager: ObservableObject {
    @Published var currentRepresentation: DNARepresentation = .doubleHelix
    @Published var colorScheme: DNAColorScheme = .byBase
    @Published var selectedRange: Range<Int>?
    @Published var highlightedFeatures: [GeneFeature] = []
    
    private var scene: SCNScene
    private var cameraNode: SCNNode
    private var helixNodes: [SCNNode] = []
    
    func buildDoubleHelix(sequence: DNASequence)
    func buildLadder(sequence: DNASequence)
    func buildBallAndStick(sequence: DNASequence)
    func animateReplication()
    func animateTranscription()
    func highlightRange(_ range: Range<Int>)
}

enum DNARepresentation {
    case doubleHelix, ladder, ballAndStick, sequenceOnly
}

enum DNAColorScheme {
    case byBase, byStrand, uniform, gcContent
}
```

---

## 4. 파일 구조
```
DNAApp/
├── Sources/
│   ├── App/
│   │   ├── DNAApp.swift              // @main
│   │   ├── ContentView.swift         // Root container
│   ├── Models/
│   │   ├── DNASequence.swift
│   │   ├── GeneFeature.swift
│   │   ├── Mutation.swift
│   │   ├── Codon.swift
│   │   ├── CodonTable.swift          // 64 코돈 매핑
│   ├── Views/
│   │   ├── HomeView.swift
│   │   ├── LibraryView.swift         // 대표 유전자 갤러리
│   │   ├── ViewerView.swift
│   │   ├── SequenceBar.swift
│   │   ├── ControlBar.swift
│   │   ├── InfoSheet.swift
│   │   ├── TranslationSheet.swift
│   │   ├── MutationSheet.swift
│   │   ├── QuizSheet.swift
│   │   ├── AnalysisSheet.swift
│   │   ├── SearchSheet.swift
│   ├── Scene/
│   │   ├── DNASceneManager.swift
│   │   ├── HelixBuilder.swift
│   │   ├── LadderBuilder.swift
│   │   ├── BallStickBuilder.swift
│   │   ├── AnimationController.swift
│   ├── Services/
│   │   ├── NCBIService.swift         // GenBank 데이터 fetch
│   │   ├── PDBService.swift          // PDB DNA 구조 fetch
│   │   ├── FASTAParser.swift
│   │   ├── CIFParser.swift           // mmCIF 파싱
│   │   ├── CacheManager.swift
│   ├── Utils/
│   │   ├── SequenceAnalyzer.swift    // GC content, ORF finder
│   │   ├── RestrictionEnzymes.swift
│   │   ├── ComplementGenerator.swift
│   │   ├── MutationSimulator.swift
│   ├── Data/
│   │   ├── SampleGenes.json          // 10개 대표 유전자
│   │   ├── CodonTable.json
│   │   ├── RestrictionSites.json
│   │   ├── QuizData.json
│   ├── Resources/
│   │   ├── Localizable.strings (en, ko)
│   │   ├── Assets.xcassets/
│   ├── Info.plist
│   ├── DNAApp.entitlements
├── DNAApp.xcodeproj/
├── README.md
└── DNA_VIEWER_SPEC.md (this file)
```

---

## 5. 기술 스택
- **언어**: Swift 5.9+
- **프레임워크**: SwiftUI, SceneKit, Combine
- **선택**: RealityKit(AR), AVFoundation(애니메이션 내레이션)
- **네트워킹**: URLSession (NCBI, PDB API)
- **저장**: UserDefaults(설정), FileManager(캐시)
- **파싱**: Custom FASTA/CIF 파서

---

## 6. 3D 렌더링 사양
### 6.1 Double Helix(이중나선)
- 두 개의 나선형 곡선(Strand A, Strand B)
- 10.5 bp/turn, 3.4 Å/bp (표준 B-DNA)
- Backbone: 실린더(회색/주황색)
- Base: 구체 또는 평면(색상: A=빨강, T=파랑, G=녹색, C=노랑)
- Hydrogen bonds: 점선(A-T 2개, G-C 3개)

### 6.2 Ladder(사다리형)
- 펼쳐진 형태
- Backbone: 두 개의 수직 막대
- Rungs: 염기쌍을 가로지르는 막대
- 색상: 염기별 구분

### 6.3 Ball-and-Stick
- 각 원자를 구체로 표현
- 결합을 실린더로 표현
- Phosphate group(PO4), Sugar(Deoxyribose), Base 구분

### 6.4 Sequence Only
- 2D 텍스트 뷰
- 색상 코딩된 문자열
- 스크롤 가능, 줌 가능

---

## 7. 교육 콘텐츠
### 7.1 설명 모드 레벨
- **초급(초·중·고)**:
  - "DNA는 생명의 설계도입니다"
  - "A는 항상 T와, G는 항상 C와 짝을 이룹니다"
  - "유전자는 단백질을 만드는 정보를 담고 있습니다"
  
- **고급(대학·전문가)**:
  - "Watson-Crick 염기쌍의 수소결합 기하학"
  - "Major/Minor groove의 구조적 특징"
  - "Z-DNA와 B-DNA의 차이"

### 7.2 퀴즈 예시
1. "다음 중 DNA를 구성하는 염기가 아닌 것은? A) Adenine B) Uracil C) Guanine D) Cytosine"
2. "이 서열의 상보적 서열은? 5'-ATCG-3'"
3. "코돈 ATG가 코딩하는 아미노산은?"
4. "BRCA1 유전자의 돌연변이는 어떤 암과 관련이 있나요?"

### 7.3 애니메이션 시나리오
- **복제(Replication)**: 
  - Helicase가 이중나선을 푸는 애니메이션
  - DNA Polymerase가 새로운 가닥을 합성
  - Leading/Lagging strand 구분
  
- **전사(Transcription)**:
  - RNA Polymerase가 DNA를 따라 이동
  - mRNA 생성
  - Exon/Intron splicing
  
- **번역(Translation)**:
  - mRNA → tRNA → Amino acid chain
  - Ribosome 애니메이션

---

## 8. 성능 최적화
- **LOD(Level of Detail)**:
  - < 1,000 bp: Full detail (모든 원자)
  - 1,000–10,000 bp: Simplified (backbone + bases)
  - > 10,000 bp: Overview (curve only) + 구간 선택 시 detail
  
- **Culling**: 카메라 FOV 밖의 노드 비활성화
- **Instancing**: 동일한 염기/backbone geometry 재사용
- **Lazy Loading**: 필요한 구간만 3D 생성
- **Cache**: 다운로드한 FASTA/CIF 파일 로컬 저장

---

## 9. 데이터 소스 예시
### 9.1 NCBI GenBank
```
URL: https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi
Parameters:
  - db=nuccore
  - id=NM_007294.4 (BRCA1 예시)
  - rettype=fasta
  - retmode=text
```

### 9.2 PDB DNA 구조
```
예시 PDB ID:
  - 1BNA: B-DNA dodecamer
  - 1D89: Z-DNA
  - 355D: DNA-protein complex
URL: https://files.rcsb.org/download/1BNA.cif
```

### 9.3 내장 샘플 데이터
```json
{
  "genes": [
    {
      "name": "BRCA1",
      "accession": "NM_007294.4",
      "chromosome": "17q21.31",
      "length": 7207,
      "summary": "유방암 감수성 유전자",
      "diseases": ["Breast cancer", "Ovarian cancer"]
    },
    ...
  ]
}
```

---

## 10. 일정 및 마일스톤
### Phase 1: 기본 뷰어 (2주)
- [x] 프로젝트 구조 설정
- [ ] FASTA 파서 구현
- [ ] Double Helix 3D 렌더링
- [ ] 기본 컨트롤(회전/확대)
- [ ] Sequence Bar

### Phase 2: 색상 & 표현 (1주)
- [ ] By Base / By Strand 색상
- [ ] Ladder / Ball-Stick 표현
- [ ] GC Content 시각화

### Phase 3: 유전 정보 (2주)
- [ ] Translation 도구
- [ ] Codon table
- [ ] ORF finder
- [ ] Gene feature 하이라이트

### Phase 4: 돌연변이 & 질병 (1주)
- [ ] Mutation simulator
- [ ] 알려진 돌연변이 데이터베이스
- [ ] 질병 연관성 표시

### Phase 5: 교육 콘텐츠 (1주)
- [ ] 설명 모드
- [ ] 퀴즈 시스템
- [ ] 대표 유전자 라이브러리

### Phase 6: 고급 기능 (1주)
- [ ] 분석 도구(Restriction sites, CpG)
- [ ] 비교 뷰어
- [ ] AR 모드(선택)

### Phase 7: 다듬기 (1주)
- [ ] 성능 최적화
- [ ] UI/UX 개선
- [ ] 다국어
- [ ] 테스트 & 버그 수정

---

## 11. 참고 자료
- NCBI E-utilities: https://www.ncbi.nlm.nih.gov/books/NBK25501/
- PDB File Formats: https://www.wwpdb.org/documentation/file-format
- DNA 구조 기초: https://www.nature.com/scitable/topicpage/dna-structure-10122838/
- Genetic Code: https://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi
- ClinVar(변이 데이터베이스): https://www.ncbi.nlm.nih.gov/clinvar/

---

## 12. 주의사항
- 의학적 진단 목적이 아님을 명시(Disclaimer)
- 변이 해석은 교육 목적으로만 사용
- 개인 유전체 데이터 업로드 금지(프라이버시)
- 모든 데이터는 공개 데이터베이스 출처

---

## 13. 향후 확장 가능성
- RNA 뷰어 통합(mRNA, tRNA, rRNA)
- Epigenetics(DNA 메틸화, 히스톤 수식) 시각화
- CRISPR 가이드 RNA 디자인 도구
- Primer 디자인 도구(PCR)
- 계통수(Phylogenetic tree) 기능
- 멀티플레이어 교육 모드(학생-교사)
- VR 지원(Vision Pro)

---

**작성일**: 2025-10-17  
**버전**: 1.0  
**담당**: AI Assistant

