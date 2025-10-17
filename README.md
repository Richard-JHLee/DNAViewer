# DNA Viewer

교육용 DNA 시각화 및 분석 애플리케이션

## 개요

DNA Viewer는 DNA 서열을 3D로 시각화하고 유전 정보를 분석할 수 있는 교육용 iOS/macOS 앱입니다.

## 주요 기능

### 1. DNA 3D 시각화
- **Double Helix (이중나선)**: 표준 B-DNA 이중나선 구조
- **Ladder (사다리형)**: 펼쳐진 사다리 형태
- **Ball-and-Stick**: 분자 수준의 원자 구조

### 2. 색상 스킴
- **By Base**: 염기별 색상 (A=빨강, T=파랑, G=녹색, C=노랑)
- **By Strand**: 가닥별 구분
- **GC Content**: GC 함량에 따른 색상 그라데이션

### 3. 유전자 분석 도구
- GC 함량 계산 및 그래프
- CpG Island 찾기
- Restriction Site (제한효소 인식 서열) 검색
- ORF (Open Reading Frame) 찾기

### 4. 번역 기능
- 6-frame translation
- 코돈 테이블 참조
- 아미노산 서열 표시
- Start/Stop 코돈 하이라이트

### 5. 돌연변이 시뮬레이터
- Point Mutation (점돌연변이)
- Insertion (삽입)
- Deletion (결실)
- Inversion (역위)
- 돌연변이 효과 분석 (Synonymous/Missense/Nonsense/Frameshift)

### 6. 대표 유전자 라이브러리
- BRCA1/BRCA2 (유방암)
- TP53 (종양억제)
- CFTR (낭포성 섬유증)
- HBB (겸상적혈구)
- APOE (알츠하이머)
- 기타 주요 질병 관련 유전자

### 7. 데이터 소스
- NCBI GenBank 연동
- PDB DNA 구조 다운로드
- 로컬 FASTA 파일 지원
- 수동 서열 입력

## 프로젝트 구조

```
DNAViewer/
├── Sources/
│   ├── App/                    # 앱 엔트리포인트
│   ├── Models/                 # 데이터 모델
│   │   ├── DNASequence.swift
│   │   ├── GeneFeature.swift
│   │   ├── Mutation.swift
│   │   └── Codon.swift
│   ├── Views/                  # UI 뷰
│   │   ├── HomeView.swift
│   │   ├── LibraryView.swift
│   │   ├── ViewerView.swift
│   │   ├── InfoSheet.swift
│   │   ├── TranslationSheet.swift
│   │   ├── MutationSheet.swift
│   │   └── AnalysisSheet.swift
│   ├── Scene/                  # 3D 렌더링
│   │   ├── DNASceneManager.swift
│   │   ├── HelixBuilder.swift
│   │   ├── LadderBuilder.swift
│   │   └── BallStickBuilder.swift
│   ├── Services/               # 네트워크 & 파싱
│   │   ├── NCBIService.swift
│   │   ├── PDBService.swift
│   │   ├── FASTAParser.swift
│   │   └── CacheManager.swift
│   ├── Utils/                  # 분석 도구
│   │   ├── SequenceAnalyzer.swift
│   │   ├── RestrictionEnzymes.swift
│   │   └── MutationSimulator.swift
│   └── Data/                   # 샘플 데이터
│       ├── SampleGenes.json
│       ├── RestrictionSites.json
│       └── QuizData.json
└── README.md
```

## 기술 스택

- **언어**: Swift 5.9+
- **UI**: SwiftUI
- **3D**: SceneKit
- **네트워킹**: URLSession (NCBI, PDB API)
- **데이터**: JSON, FASTA, mmCIF 파싱

## 빌드 방법

### macOS 빌드
```bash
xcodebuild -project DNAViewer.xcodeproj \
  -scheme DNAViewer \
  -configuration Debug \
  -destination 'platform=macOS' \
  build
```

### iOS 시뮬레이터 빌드
```bash
xcodebuild -project DNAViewer.xcodeproj \
  -scheme DNAViewer \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build
```

## 사용 방법

### 1. 샘플 유전자 탐색
- 홈 화면에서 "Sample Genes Library" 선택
- 관심 유전자 카드 클릭
- 3D 뷰어에서 구조 확인

### 2. 새로운 서열 불러오기
- "Load New Sequence" 선택
- GenBank Accession 입력 (예: NM_007294.4)
- 또는 PDB ID 입력 (예: 1BNA)
- 또는 직접 DNA 서열 입력 (ATGC)

### 3. 3D 뷰어 사용
- 스와이프/드래그로 회전
- 핀치로 확대/축소
- 하단 컨트롤바에서 표현 방식 변경
- 색상 스킴 변경
- 서열 바에서 특정 위치 선택

### 4. 분석 도구 사용
- 🔬 아이콘 클릭
- GC Content, CpG Islands, Restriction Sites 탭 선택
- 결과 확인 및 내보내기

### 5. 돌연변이 시뮬레이션
- ⚡️ 아이콘 클릭
- 돌연변이 타입 선택
- 위치와 파라미터 입력
- "Simulate Mutation" 실행
- 결과 분석 (Synonymous/Missense/Nonsense/Frameshift)

## 성능 최적화

- **LOD (Level of Detail)**
  - < 1,000 bp: 전체 상세도
  - 1,000–10,000 bp: 간소화
  - > 10,000 bp: 개요 + 구간 선택 시 상세 렌더링

- **캐싱**
  - 다운로드한 FASTA/CIF 파일 로컬 저장
  - 최근 본 항목 관리

- **지오메트리 재사용**
  - Instancing으로 동일한 염기/백본 재사용

## 교육 콘텐츠

### 설명 모드
- 초급: 초·중·고등학생용
- 고급: 대학생·전문가용

### 퀴즈
- DNA 구조 기초
- 염기쌍 규칙
- 코돈과 번역
- 유전자와 질병

## 주의사항

⚠️ **면책 조항**
- 본 앱은 교육 목적으로만 사용됩니다
- 의학적 진단이나 치료 결정에 사용하지 마십시오
- 변이 해석은 전문가의 자문을 받아야 합니다
- 개인 유전체 데이터를 업로드하지 마십시오

## 참고 자료

- [NCBI E-utilities](https://www.ncbi.nlm.nih.gov/books/NBK25501/)
- [PDB File Formats](https://www.wwpdb.org/documentation/file-format)
- [DNA Structure](https://www.nature.com/scitable/topicpage/dna-structure-10122838/)
- [Genetic Code](https://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi)

## 라이선스

Educational Use Only

## 버전

**Version 1.0** - 2025-10-17

## 작성자

AI Assistant

---

상세한 기획 내용은 `DNA_VIEWER_SPEC.md` 파일을 참조하세요.

