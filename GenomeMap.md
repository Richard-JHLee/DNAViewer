ROLE: Senior iOS bioinformatics dev agent.

GOAL:
SwiftUI + Canvas 기반 Genome Map.
사용자가 "BRCA1"를 검색하면 Ensembl API로 Chr, start/end, 근처 유전자(TP53 등)를 가져와 상단 이데오그램에 마커로 표시. BRCA1을 탭하면 하단에 “0–20 bp 시퀀스”가 펼쳐지는데, 이 시퀀스는 사용자가 고른 “그룹(트랜스크립트/엑손/영역)”에 따라 바뀐다.

SCOPE:
- iOS 17+, Swift 5.10, SwiftUI/Canvas/async-await
- 네트워킹: Ensembl REST API
- 폴더 구조: Models/, Services/, ViewModels/, Views/

FEATURES:
1) 검색(TextField) → Ensembl lookup/symbol로 BRCA1 메타데이터 로드:
   GET https://rest.ensembl.org/lookup/symbol/homo_sapiens/{symbol}?content-type=application/json
   파싱: id, display_name, seq_region_name (chromosome), start, end, strand

2) 주변 유전자(예: TP53 등) 로드(±5Mb):
   GET https://rest.ensembl.org/overlap/region/homo_sapiens/{chr}:{start-5_000_000}-{end+5_000_000}?feature=gene;content-type=application/json
   → 캔버스 이데오그램에 마커(이름 라벨)로 표시, BRCA1은 강조색

3) BRCA1을 탭하면 하단 상세 뷰(SequenceDetailView)가 펼쳐짐.
   상세 뷰 상단에 “그룹 선택 UI(Picker or Segmented)” 제공:
   - GroupType:
     a) Gene (대표 유전자 단위)
     b) Transcript (주 트랜스크립트 하나 또는 선택)
     c) Exon (선택한 트랜스크립트의 엑손 목록 중 하나)
     d) Region (사용자 정의 범위: [start, end])
   기본은 Gene.

4) 그룹별 시퀀스 취득 규칙:
   a) Gene: sequence/id/{gene_id} (FASTA) 중 5' 기준 0–19 bp
      GET https://rest.ensembl.org/sequence/id/{gene_id}?content-type=text/plain
   b) Transcript: lookup/id/{gene_id}?expand=1로 대표 트랜스크립트 ID를 얻은 후 sequence/id/{transcript_id}
      GET https://rest.ensembl.org/lookup/id/{gene_id}?expand=1
      GET https://rest.ensembl.org/sequence/id/{transcript_id}?content-type=text/plain
   c) Exon: lookup/id/{gene_id}?expand=1 응답의 exons 배열에서 선택된 exon의 genomic 좌표를 사용해 sequence/region 호출
      GET https://rest.ensembl.org/sequence/region/homo_sapiens/{chr}:{exon_start}..{exon_end}:{strand}?content-type=text/plain
   d) Region: sequence/region/homo_sapiens/{chr}:{userStart}..{userEnd}:{strand}
      GET https://rest.ensembl.org/sequence/region/homo_sapiens/{chr}:{s}..{e}:{strand}?content-type=text/plain

5) “0–20 bp” 표시는 **그룹 로컬 좌표의 5'→3' 방향 기준**으로 다음을 적용:
   - 양(+1) 가닥: slice = seq[0..<min(20, len)]
   - 음(-1) 가닥: slice = 마지막 20bp를 **역상보(reverse-complement)**해서 5'→3'로 표시
   - len < 20이면 가능한 길이만 표시(표 제목에 'N=xx bp' 표기)
   - 컬러: A=red, T=blue, G=green, C=yellow, Canvas에서 박스+문자

6) UI:
   - 상단: ChromosomeIdeogramView(Canvas). 마커 탭 → 선택 gene 바인딩 변경.
   - 하단: SequenceDetailView(sequence: String, groupType: GroupType, meta: GroupMeta)
     Group Picker (SegmentedControl or Menu)
     Transcript/Exon 선택 시 보조 Picker 노출.
     Region 선택 시 start/end 텍스트 필드(정수, 유효성 검사) 노출.
   - 로딩/에러 표시(ProgressView / inline 메시지)

7) 상태 관리(ViewModel):
   GeneViewModel
   - @Published searchQuery, selectedGene, neighbors[], chromosomeLength (상수 or API 기반)
   - selectedGroupType: GroupType
   - selectedTranscriptID, selectedExonIndex, regionStart, regionEnd
   - sequence20: 계산 프로퍼티(위 규칙으로 0–20bp 가공), 원본 seq 캐싱(Map: cacheKey → String)

8) 성능/캐싱:
   - 단순 in-memory cache (Dictionary<String,String>)
   - cacheKey 예: "gene:{id}", "tx:{id}", "exon:{id}", "region:{chr}:{s}-{e}:{strand}"

ACCEPTANCE CRITERIA:
- “BRCA1” 검색 → 상단 Chr17에 BRCA1/TP53 등 주변 마커 표시(동적 데이터).
- 하단 상세에서 GroupType 변경 시, 0–20 bp 시퀀스가 즉시 변경:
  * Gene ↔ Transcript ↔ Exon ↔ Region 전환 시 서로 다른 조각이 노출.
- strand==-1인 트랜스크립트/엑손은 역상보로 5'→3' 방향으로 올바르게 표시.
- SequenceDetailView에서 길이<20인 경우에도 정상 동작(N=xx)과 함께 부분 표시.
- 네트워크 오류 시 사용자 친화적 메시지와 재시도 제공.
- iOS 17+, Xcode 15+에서 빌드/실행 OK.

FILES:

**Models/**
- `GeneModel.swift`: Gene 데이터 모델 (id, display_name, seq_region_name, start, end, strand)
- `TranscriptModel.swift`: Transcript 데이터 모델 (id, start, end, strand, exons[])
- `ExonModel.swift`: Exon 데이터 모델 (id, start, end, strand)
- `GroupType.swift`: Enum (Gene, Transcript, Exon, Region)
- `GroupMeta.swift`: 그룹별 메타데이터 (type, transcriptID, exonIndex, regionStart, regionEnd)

**Services/**
- `EnsemblAPIService.swift`: Ensembl REST API 통신
  - `lookupSymbol(_:)` → Gene 정보 조회
  - `getNeighboringGenes(_:)` → ±5Mb 범위 유전자들 조회
  - `getSequence(for:type:)` → 그룹별 시퀀스 조회
  - `getTranscripts(for:)` → 유전자의 트랜스크립트 목록
- `SequenceProcessor.swift`: 시퀀스 처리 유틸리티
  - `reverseComplement(_:)` → 역상보 변환
  - `sliceSequence(_:length:)` → 0-20bp 슬라이싱
  - `getSequenceColor(_:)` → 염기별 색상 반환

**ViewModels/**
- `GeneViewModel.swift`: 메인 상태 관리
  - `@Published var searchQuery: String`
  - `@Published var selectedGene: GeneModel?`
  - `@Published var neighboringGenes: [GeneModel]`
  - `@Published var selectedGroupType: GroupType`
  - `@Published var sequence20: String` (계산 프로퍼티)
  - `private var sequenceCache: [String: String]` (캐싱)

**Views/**
- `GenomeMapView.swift`: 메인 컨테이너 뷰
- `ChromosomeIdeogramView.swift`: Canvas 기반 염색체 이데오그램
  - 마커 렌더링 (BRCA1 강조, 주변 유전자들)
  - 탭 제스처로 유전자 선택
- `SequenceDetailView.swift`: 하단 상세 뷰
  - GroupType Picker (SegmentedControl)
  - Transcript/Exon 보조 Picker
  - Region 입력 필드 (start/end)
  - 0-20bp 시퀀스 표시 (Canvas 박스+문자)
- `SequenceBoxView.swift`: 개별 염기 박스 컴포넌트
- `LoadingView.swift`: 로딩/에러 상태 표시

**API Endpoints Used:**
1. `GET https://rest.ensembl.org/lookup/symbol/homo_sapiens/{symbol}` - 유전자 메타데이터
2. `GET https://rest.ensembl.org/overlap/region/homo_sapiens/{chr}:{start}-{end}?feature=gene` - 주변 유전자
3. `GET https://rest.ensembl.org/sequence/id/{gene_id}` - 유전자 시퀀스
4. `GET https://rest.ensembl.org/lookup/id/{gene_id}?expand=1` - 트랜스크립트 정보
5. `GET https://rest.ensembl.org/sequence/id/{transcript_id}` - 트랜스크립트 시퀀스
6. `GET https://rest.ensembl.org/sequence/region/homo_sapiens/{chr}:{start}..{end}:{strand}` - 영역 시퀀스

**Data Flow:**
1. 사용자 검색 → EnsemblAPIService.lookupSymbol() → GeneModel 생성
2. 선택된 유전자 → getNeighboringGenes() → ChromosomeIdeogramView 마커 업데이트
3. 유전자 탭 → SequenceDetailView 표시 → GroupType 선택
4. 그룹 변경 → getSequence(for:type:) → sequence20 계산 프로퍼티 업데이트
5. Canvas 렌더링 → SequenceBoxView로 개별 염기 표시

NOTES (Implementation details):
- 좌표 정규화: xRatio = (geneMid - chrStart) / (chrEnd - chrStart)
- 역상보: reverse(complement(seq)); complement: A↔T, G↔C
- 색: A=red, T=blue, G=green, C=yellow (Color 고정 팔레트)
- 접근성: 문자 라벨 병행, Dynamic Type 고려
- 모듈성: 서비스/뷰모델 테스트 가능하게 분리

AFTER COMPLETION:
- 생성/수정 파일 목록과 주요 함수 요약
- “BRCA1”로 실행한 스크린샷 설명(Chr17 마커 + Group 전환에 따른 0–20bp 변환 사례)
- 간단 부하 테스트(N=20, Group 전환 50회) 후 메모리 누수 징후 여부 보고