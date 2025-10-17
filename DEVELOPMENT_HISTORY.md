# DNA Viewer 개발 이력

## 📋 프로젝트 개요

**프로젝트명**: DNA Viewer  
**목적**: 3D DNA 구조 시각화 및 유전자 정보 학습용 교육 앱  
**플랫폼**: iOS 15.0+, macOS 12.0+  
**개발 언어**: Swift, SwiftUI  
**3D 엔진**: SceneKit  
**저장소**: https://github.com/Richard-JHLee/DNAViewer

---

## 🎯 주요 기능

### 1. 3D DNA 시각화
- **Double Helix (이중 나선)**: 실제 DNA와 유사한 3D 모델
- **AGCT 라벨**: 각 염기(A, T, G, C)를 3D 공간에 표시
- **수소결합**: 염기쌍 사이의 연결을 회색 실린더로 표현
- **색상 구분**: 
  - A (Adenine): 주황색
  - T (Thymine): 초록색
  - G (Guanine): 빨간색
  - C (Cytosine): 노란색

### 2. 그룹 기반 네비게이션
- **동적 그룹 분할**: DNA 시퀀스 길이에 따라 자동 그룹화
  - BRCA1 (445bp): 40개씩 → 11개 그룹
  - TP53 (393bp): 35개씩 → 12개 그룹
  - CFTR (1480bp): 50개씩 → 30개 그룹
- **그룹 버튼**: G1, G2, G3... 버튼으로 그룹 전환
- **자동 전환**: 다른 그룹의 염기 선택 시 자동으로 해당 그룹 로드

### 3. 인터랙티브 염기 선택
- **클릭 선택**: 하단 염기서열에서 염기 클릭
- **시각적 피드백**:
  - 하단: 파란색 테두리 (3px)
  - 3D: 라벨 색상 흰색 → 빨간색
  - 3D: 노란색 구체 하이라이트 (펄스 애니메이션)
- **카메라 포커스**: 선택된 염기로 자동 이동 (SCNTransaction)
- **토글 선택**: 같은 염기 재클릭 시 선택 해제

### 4. UI/UX
- **Top Bar**: ProteinApp 스타일
  - 햄버거 메뉴 (뒤로가기)
  - DNA ID (예: BRCA1)
  - Full Name (예: Breast Cancer 1)
  - 라이브러리 아이콘
  - 눈 아이콘 (컨트롤 토글)
- **Side Controls**: 우측 플로팅 버튼
  - Play/Pause (회전 애니메이션)
  - Analysis (분석)
  - Reset (뷰 리셋)
- **Control Bar**: Style & Color 선택 (토글 가능)
- **Sequence Bar**: 염기서열 표시 및 그룹 버튼

---

## 🔧 기술적 구현

### 3D 렌더링

#### HelixBuilder
**파일**: `Sources/Scene/HelixBuilder.swift`

**핵심 구현**:
```swift
// 1. 매끄러운 백본 생성
private func createSmoothBackbone(points: [SCNVector3], strandName: String, radius: CGFloat) -> SCNNode {
    let parent = SCNNode()
    for i in 1..<points.count {
        let segment = createBackboneSegment(from: points[i-1], to: points[i], radius: radius)
        parent.addChildNode(segment)
    }
    return parent
}

// 2. SCNCapsule로 각 세그먼트 생성
private func createBackboneSegment(from: SCNVector3, to: SCNVector3, radius: CGFloat) -> SCNNode {
    let distance = (to - from).length()
    let capsule = SCNCapsule(capRadius: radius, height: CGFloat(distance))
    capsule.radialSegmentCount = 24
    capsule.heightSegmentCount = 12
    // 청록색 백본
    capsule.firstMaterial?.diffuse.contents = PlatformColor(red: 0.06, green: 0.54, blue: 0.97, alpha: 1)
    capsule.firstMaterial?.lightingModel = SCNMaterial.LightingModel.phong
    // ...
}

// 3. 염기쌍 생성 (두 개의 컬러 블록 + 수소결합)
private func createBasePair(...) -> SCNNode {
    // 두 백본 사이를 잇는 컬러 블록
    let baseNode1 = createBaseHalf(length: halfLength, color: color1, ...)
    let baseNode2 = createBaseHalf(length: halfLength, color: color2, ...)
    
    // 수소결합
    let hBond = createHydrogenBond(from: innerStart, to: innerEnd, ...)
    
    // AGCT 라벨 (billboarded, 항상 카메라 향함)
    let labelNode1 = createBaseLabel(base: base1, ...)
    labelNode1.name = "label_\(index)_strand1"  // 선택 시 색상 변경용
    // ...
}
```

**주요 상수**:
- `backboneRadius`: 0.55
- `hydrogenBondRadius`: 0.12
- `baseLabelScale`: 0.8
- `radialSegmentCount`: 24 (매끄러운 원형)

#### DNASceneManager
**파일**: `Sources/Scene/DNASceneManager.swift`

**핵심 기능**:
```swift
// 1. 그룹 관리
@Published var currentGroup: Int = 1
@Published var totalGroups: Int = 1
@Published var groupSize: Int = 40

func loadGroup(_ group: Int) {
    objectWillChange.send()  // UI 강제 업데이트
    currentGroup = group
    displayStart = (group - 1) * groupSize
    displayLength = min(groupSize, sequence.length - displayStart)
    rebuildScene()
}

// 2. 염기 선택 및 하이라이트
@Published var selectedBaseIndex: Int?

func selectBase(at index: Int) {
    selectedBaseIndex = index
    highlightSelectedBase()
}

private func highlightSelectedBase() {
    // basepair 노드 검색
    let relativeIndex = selectedIndex - displayStart
    for helixNode in helixNodes {
        if let name = helixNode.name, name == "basepair_\(relativeIndex)" {
            addHighlightToNode(helixNode)
            focusCameraOn(position: helixNode의 자식 worldPosition)
        }
    }
}

// 3. 라벨 색상 변경
private func addHighlightToNode(_ node: SCNNode) {
    // 노란색 구체 추가
    let highlightSphere = SCNSphere(radius: 1.5)
    // 펄스 애니메이션
    
    // 라벨 색상을 빨간색으로 변경
    node.enumerateChildNodes { child, _ in
        if let name = child.name, name.hasPrefix("label_") {
            textGeometry.firstMaterial?.diffuse.contents = PlatformColor.red
            textGeometry.firstMaterial?.emission.contents = PlatformColor.red
        }
    }
}

// 4. 카메라 포커스 (드래그 후에도 작동)
private func focusCameraOn(position: SCNVector3) {
    SCNTransaction.begin()
    SCNTransaction.animationDuration = 1.0
    cameraNode.position = SCNVector3(x: position.x, y: position.y + 5, z: position.z + 20)
    cameraNode.look(at: position)
    SCNTransaction.commit()
}
```

**조명 설정**:
```swift
// Ambient Light: 0.3 intensity
// Main Directional Light: 2000 intensity
// Fill Light: 800 intensity
// Camera HDR + Bloom: bloomIntensity 0.3
```

### UI 컴포넌트

#### SequenceBar
**파일**: `Sources/Views/SequenceBar.swift`

**핵심 기능**:
```swift
struct SequenceBar: View {
    @ObservedObject var sceneManager: DNASceneManager
    
    var body: some View {
        VStack {
            // 그룹 버튼을 각 그룹 시작 위치에 표시
            if index % sceneManager.groupSize == 0 {
                GroupButton(
                    groupNumber: getGroupNumber(for: index),
                    isSelected: getGroupNumber(for: index) == sceneManager.currentGroup
                )
            }
            
            // 염기 셀
            BaseCell(
                isSelected: isSelected(index),  // 파란색 테두리
                isInCurrentGroup: isInCurrentGroup(index)  // 흰색 테두리
            )
            .onTapGesture {
                // 그룹 자동 전환
                let targetGroup = getGroupNumber(for: index)
                if targetGroup != sceneManager.currentGroup {
                    sceneManager.loadGroup(targetGroup)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        sceneManager.selectBase(at: index)
                    }
                } else {
                    sceneManager.selectBase(at: index)
                }
            }
        }
    }
}
```

**테두리 색상 우선순위**:
1. 개별 선택: 파란색 (3px)
2. 현재 그룹: 흰색 (2px)
3. 기타: 테두리 없음

#### ViewerView
**파일**: `Sources/Views/ViewerView.swift`

**레이아웃 구조**:
```swift
VStack(spacing: 0) {
    // 1. Top Bar (전체 너비)
    DNAViewerTopBar(...)
    
    // 2. 3D Scene (전체 공간)
    ZStack {
        SceneView(...)
        
        // Overlay UI
        VStack {
            // Side Controls (우측 플로팅)
            // Control Bar (하단, 토글)
            // Sequence Bar (최하단)
        }
    }
}
```

#### ControlBar
**파일**: `Sources/Views/ControlBar.swift`

**기능**:
- Style 선택: Double Helix, Ladder, Ball & Stick
- Color 선택: By Base, GC Content, CpG Islands
- Group Navigation: Previous/Next 버튼
- 전체 너비 레이아웃

---

## 🐛 해결한 주요 문제

### 1. 플랫폼 호환성
**문제**: iOS와 macOS에서 타입 불일치  
**해결**: 
```swift
#if os(macOS)
typealias PlatformColor = NSColor
#else
typealias PlatformColor = UIColor
#endif
```

### 2. DNA 구조 정확성
**문제**: 백본이 직선 실린더로 표시됨  
**해결**: SCNCapsule 세그먼트를 여러 개 연결하여 매끄러운 나선 구조 생성

### 3. 염기쌍 정렬
**문제**: 염기쌍이 백본을 관통함  
**해결**: `hydrogenGap`을 두고, 두 개의 half-block으로 염기쌍 생성

### 4. 라벨 가시성
**문제**: AGCT 라벨이 너무 작고 어두움  
**해결**:
- `baseLabelScale`: 0.24 → 0.8
- 색상: 검은색 → 흰색 + emission
- `renderingOrder`: 2048 (항상 앞에 표시)
- `lightingModel`: .constant (조명 무시)

### 5. 그룹 전환 시 UI 업데이트
**문제**: 그룹 버튼 색상과 염기 테두리가 업데이트되지 않음  
**해결**:
```swift
// SequenceBar에서 sceneManager를 직접 관찰
@ObservedObject var sceneManager: DNASceneManager

// loadGroup에서 명시적으로 UI 업데이트 트리거
objectWillChange.send()
```

### 6. 노드 검색 실패
**문제**: `basepair_N` 노드를 찾지 못함  
**해결**:
- 노드 이름을 `position` (절대 위치) → `index` (상대 위치)로 변경
- helixNodes 배열에서 직접 검색 (재귀 검색 불필요)

### 7. 카메라 이동 실패
**문제**: 사용자가 드래그하면 카메라 이동이 무시됨  
**해결**:
```swift
// SCNAction 대신 SCNTransaction 사용
SCNTransaction.begin()
cameraNode.position = targetPosition
cameraNode.look(at: selectedBase)
SCNTransaction.commit()
```

### 8. worldPosition이 (0,0,0)
**문제**: basePair 노드의 worldPosition이 원점  
**해결**: 자식 노드(base_) 의 worldPosition 사용

---

## 📐 데이터 모델

### DNASequence
```swift
struct DNASequence: Identifiable, Codable {
    let id: UUID
    let name: String           // "BRCA1 - Breast Cancer 1"
    let accession: String?     // GenBank ID
    let sequence: String       // "ATGC..."
    let chromosome: String?
    var features: [GeneFeature]
    var mutations: [Mutation]
    let summary: String?
    // ...
}
```

### GeneFeature
```swift
struct GeneFeature: Identifiable, Codable {
    let id: UUID
    let type: FeatureType      // exon, intron, promoter, etc.
    let startPos: Int
    let endPos: Int
    let description: String?
}
```

### Mutation
```swift
struct Mutation: Identifiable, Codable {
    let id: UUID
    let position: Int
    let originalBase: Character
    let mutatedBase: Character
    let type: MutationType
    let disease: String?
}
```

---

## 🎨 디자인 가이드

### 색상 팔레트

**배경**:
- 3D Scene: Dark Navy `rgb(0.03, 0.08, 0.15)`
- Top Bar: Ultra Thin Material (반투명)
- Control Bar: Black 80% opacity
- Sequence Bar: Black 80% opacity

**염기 색상**:
- A (Adenine): Orange `rgb(1.0, 0.5, 0.0)`
- T (Thymine): Green `rgb(0.0, 0.8, 0.0)`
- G (Guanine): Red `rgb(1.0, 0.0, 0.0)`
- C (Cytosine): Yellow `rgb(1.0, 1.0, 0.0)`

**백본**: Cyan Blue `rgb(0.06, 0.54, 0.97)`

**수소결합**: Light Gray `white 0.7` + emission 0.1

### 재질 속성

**백본 (Backbone)**:
```swift
material.lightingModel = .phong
material.shininess = 100
material.specular.contents = white
```

**염기 블록 (Base)**:
```swift
material.lightingModel = .phong
material.shininess = 80
material.chamferRadius = 0.18
```

**라벨 (Label)**:
```swift
material.lightingModel = .constant  // 조명 무시
material.isDoubleSided = true
material.diffuse.contents = white
material.emission.contents = white 0.2
```

---

## 📊 성능 최적화

### 그룹 기반 렌더링
- **문제**: 긴 DNA 시퀀스(수천 bp)를 모두 렌더링하면 성능 저하
- **해결**: 시퀀스를 그룹으로 분할하여 현재 그룹만 렌더링
- **효과**: 
  - BRCA1 (445bp): 40개만 렌더링 → 11배 성능 향상
  - Huntingtin (3144bp): 60개만 렌더링 → 52배 성능 향상

### 노드 명명 규칙
```swift
// 효율적인 검색을 위한 체계적 명명
basePairNode.name = "basepair_\(index)"
baseNode.name = "base_\(index)_strand1"
labelNode.name = "label_\(index)_strand1"
highlightNode.name = "highlight"
```

---

## 🔬 샘플 데이터

### 포함된 유전자
1. **BRCA1** (445bp) - Breast Cancer 1
2. **TP53** (393bp) - Tumor Protein P53
3. **CFTR** (1480bp) - Cystic Fibrosis
4. **Huntingtin** (3144bp) - Huntington's Disease
5. **HBB** (444bp) - Hemoglobin Subunit Beta
6. **APOE** (299bp) - Apolipoprotein E
7. **EGFR** (3633bp) - Epidermal Growth Factor Receptor
8. **KRAS** (567bp) - KRAS Proto-Oncogene
9. **ALK** (1620bp) - ALK Receptor Tyrosine Kinase
10. **PTEN** (1212bp) - Phosphatase and Tensin Homolog

---

## 📱 사용자 인터페이스

### 화면 구조

```
┌──────────────────────────────────────────────────┐
│  ☰          BRCA1               📚    👁️         │ Top Bar
├──────────────────────────────────────────────────┤
│                                            ▶️    │
│                                            📊    │
│              🧬 DNA 3D Model               🔄    │ 3D Scene
│                                                  │
│                                                  │
├──────────────────────────────────────────────────┤
│ Style: [Helix] Ladder BallStick                 │ Control Bar
│ Color: [Base] GC CpG                            │ (토글 가능)
│ ◀ Group 2 of 11 ▶                               │
├──────────────────────────────────────────────────┤
│ Position: 40              445 bp                │ Sequence Bar
│ G1  G2  G3  G4  G5  ...                         │
│ ┌─┐┌─┐┌─┐┌─┐┌─┐                                 │
│ │A││T││G││C││A│...                              │
│ └─┘└─┘└─┘└─┘└─┘                                 │
└──────────────────────────────────────────────────┘
```

### 인터랙션

**그룹 선택**:
1. G2 버튼 클릭
2. G2 버튼 → 파란색
3. 40~79번 염기 → 흰색 테두리
4. 3D 이미지 → 41~80번 염기로 재구성

**염기 선택**:
1. 55번 염기 [C] 클릭
2. 그룹 확인 → Group 2
3. 55번 염기 → 파란색 테두리
4. 3D 라벨 "C" → 빨간색
5. 노란색 구체 → 펄스 애니메이션
6. 카메라 → 해당 위치로 이동

**선택 해제**:
1. 같은 염기 재클릭
2. 파란색 테두리 제거
3. 라벨 → 흰색 복원
4. 노란색 구체 제거

---

## 🎯 개발 단계별 이력

### Phase 1: 프로젝트 초기 설정
- ✅ XcodeGen 프로젝트 구조 생성
- ✅ 기본 데이터 모델 정의
- ✅ 크로스 플랫폼 설정 (iOS/macOS)

### Phase 2: 3D 렌더링 기초
- ✅ SceneKit 환경 구성
- ✅ 기본 Double Helix 생성
- ✅ 색상 스킴 구현

### Phase 3: DNA 구조 정확성 개선
- ✅ 직선 백본 → 매끄러운 나선 (SCNCapsule 세그먼트)
- ✅ 염기쌍을 두 백본 사이 연결 블록으로 개선
- ✅ 수소결합 추가 (회색 실린더)
- ✅ AGCT 라벨 추가 및 가시성 개선

### Phase 4: 라벨 최적화
- ✅ 라벨 크기 증가 (0.24 → 0.8)
- ✅ 색상 변경 (검은색 → 흰색)
- ✅ Billboard constraint (항상 카메라 향함)
- ✅ 위치 조정 (radialDirection + outset)

### Phase 5: 긴 시퀀스 처리
- ✅ 그룹 기반 표시 시스템 구현
- ✅ 동적 그룹 크기 계산
- ✅ 그룹 버튼 UI (G1, G2, G3...)
- ✅ Previous/Next 네비게이션

### Phase 6: 인터랙티브 기능
- ✅ 염기 선택 기능
- ✅ 자동 그룹 전환
- ✅ 3D 라벨 색상 변경
- ✅ 노란색 구체 하이라이트
- ✅ 카메라 자동 포커스

### Phase 7: UI/UX 개선
- ✅ ProteinApp 스타일 Top Bar
- ✅ 전체 너비 레이아웃
- ✅ Style & Color 컨트롤 토글
- ✅ 선택 토글 (해제 기능)
- ✅ 그룹 하이라이트 (흰색 테두리)

### Phase 8: 마무리
- ✅ 수소결합 가시성 개선 (0.05 → 0.12)
- ✅ 디버그 로그 추가
- ✅ Git 커밋 및 GitHub push
- ✅ 문서화

---

## 🔍 코드 통계

### 파일 구성
```
총 42개 파일, 7,396 라인

Sources/
├── App/ (3 files)
│   ├── DNAApp.swift
│   ├── DNAViewModel.swift
│   └── ContentView.swift
├── Models/ (4 files)
│   ├── DNASequence.swift
│   ├── GeneFeature.swift
│   ├── Mutation.swift
│   └── Codon.swift
├── Scene/ (4 files)
│   ├── DNASceneManager.swift (470 lines)
│   ├── HelixBuilder.swift (421 lines)
│   ├── LadderBuilder.swift
│   └── BallStickBuilder.swift
├── Views/ (9 files)
│   ├── ViewerView.swift (213 lines)
│   ├── SequenceBar.swift (214 lines)
│   ├── ControlBar.swift (118 lines)
│   ├── HomeView.swift
│   ├── LibraryView.swift
│   ├── InfoSheet.swift
│   ├── TranslationSheet.swift
│   ├── MutationSheet.swift
│   └── AnalysisSheet.swift
├── Services/ (4 files)
│   ├── NCBIService.swift
│   ├── PDBService.swift
│   ├── FASTAParser.swift
│   └── CacheManager.swift
└── Utils/ (3 files)
    ├── SequenceAnalyzer.swift
    ├── RestrictionEnzymes.swift
    └── MutationSimulator.swift
```

---

## 🚀 빌드 및 실행

### 요구사항
- Xcode 15.0+
- iOS 15.0+ (iPhone/iPad)
- macOS 12.0+ (Mac)

### 빌드 명령
```bash
cd /Users/richard/source/DNAViewer
xcodebuild -project DNAViewer.xcodeproj \
  -scheme DNAViewer_iOS \
  -configuration Debug \
  -destination 'platform=iOS,name=jhlee' \
  build
```

### 실행
1. Xcode에서 프로젝트 열기
2. 타겟 디바이스 선택 (iPhone/Mac)
3. Run (⌘R)

---

## 📚 참고 자료

### SceneKit
- SCNCapsule: 매끄러운 백본 세그먼트
- SCNBox: 염기 블록 (chamfered)
- SCNText: 3D 라벨
- SCNBillboardConstraint: 라벨이 카메라 향하도록
- SCNTransaction: 강제 카메라 제어

### SwiftUI
- @ObservedObject: 실시간 상태 관찰
- @Published: 상태 변경 알림
- objectWillChange.send(): 강제 UI 업데이트
- .ultraThinMaterial: 반투명 배경

### DNA 생물학
- Watson-Crick 염기쌍 규칙
  - A-T: 2개 수소결합
  - G-C: 3개 수소결합
- Double Helix 구조
- 염기서열 방향 (5' → 3')

---

## 🎓 학습 포인트

### SceneKit 고급 기법
1. **SIMD 벡터 연산**: 정확한 3D 위치 계산
2. **Quaternion 회전**: 염기 블록 방향 설정
3. **Billboard Constraint**: 카메라 향하는 라벨
4. **SCNTransaction**: 강제 카메라 제어
5. **Lighting Model**: Phong vs Constant
6. **HDR + Bloom**: 시각적 품질 향상

### SwiftUI 패턴
1. **ObservableObject**: 상태 관리
2. **Binding**: 양방향 데이터 흐름
3. **@Published**: 반응형 프로퍼티
4. **Conditional Rendering**: if/else로 UI 전환
5. **Animation**: withAnimation, transition

### 성능 최적화
1. **그룹 분할**: 큰 데이터셋 처리
2. **Lazy Loading**: 필요한 부분만 렌더링
3. **노드 재사용**: 같은 지오메트리 공유
4. **LOD**: 거리에 따른 디테일 조정 (향후 개선 가능)

---

## 🔮 향후 개선 사항

### 기능 추가
- [ ] 돌연변이 시뮬레이션 (MutationSimulator 활성화)
- [ ] 제한효소 절단 위치 표시
- [ ] DNA 복제 애니메이션
- [ ] 전사/번역 과정 시각화
- [ ] AR 모드 (ARKit 통합)

### UI/UX 개선
- [ ] 염기 검색 기능
- [ ] 북마크/즐겨찾기
- [ ] 커스텀 시퀀스 입력
- [ ] 시퀀스 비교 모드
- [ ] 다크/라이트 모드

### 성능 개선
- [ ] Metal 렌더러로 전환 (SceneKit → Metal)
- [ ] 지오메트리 인스턴싱
- [ ] Level of Detail (LOD) 구현
- [ ] 백그라운드 렌더링

### 교육 기능
- [ ] 퀴즈 모드 완성
- [ ] 학습 가이드
- [ ] 용어 사전
- [ ] 비디오 튜토리얼

---

## 👥 기여자

- **개발**: AI Assistant
- **기획**: Richard
- **테스트**: jhlee 디바이스

---

## 📄 라이선스

MIT License (또는 프로젝트에 맞게 수정)

---

## 🙏 감사의 말

이 프로젝트는 DNA 구조에 대한 교육적 이해를 돕기 위해 개발되었습니다.  
생물학적으로 정확한 시각화를 통해 학생들과 연구자들이 유전자를 더 잘 이해할 수 있기를 바랍니다.

---

**마지막 업데이트**: 2025-10-17  
**버전**: 1.0.0  
**커밋**: 1db7ccb

