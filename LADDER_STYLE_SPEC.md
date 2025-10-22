# Ladder 2D Style - K-세그먼트 균등 분배 구현

## 구현 완료 현황 (2025-01-22)

### ✅ 완료된 기능

#### 1. 2D Ladder 시각화 구조
- **4번 만나는 지점(노드) 생성**: K=4 교차점 → 총 5개 노드 (0, 1, 2, 3, 4)
- **사인 곡선 백본**: 왼쪽/오른쪽 가닥이 위상 π 차이로 교차
- **균일한 노드 간격**: `omega = (K + 1) * π / height`로 보장

#### 2. 구간별 염기쌍 균등 분배 알고리즘
```
5개 구간 (0-1, 1-2, 2-3, 3-4 구간)
- 끝단 구간 (0-1, 3-4): 0.5 가중치 (덜 배치)
- 중간 구간 (1-2, 2-3): 1.0 가중치 (더 배치)
- 20개 염기쌍 예시 분배: (2, 5, 6, 5, 2) 또는 (3, 5, 5, 5, 2)
- 소수점 나머지는 소수부가 큰 구간부터 +1 배정
```

**수학적 공식:**
```
w_0=w_K=0.5, w_j=1 (j=1,...,K-1)
W = Σw_j = K
이상적 분배: n̂_j = (w_j/W) × N
정수화: n_j = ⌊n̂_j⌋
잔여 R = N - Σn_j (소수부 큰 순서로 +1 배정)
```

#### 3. Half-step 배치
- 각 구간 내부를 n등분하여 염기쌍 배치
- 위치 공식: `y = yStart + (k + 0.5) * dy`
- 노드 위에 직접 올리지 않음 (구간 내부에만 배치)

#### 4. 시각적 요소
**백본 (Backbone):**
- 보라색 곡선 (rgb: 0.64, 0.59, 0.93)
- 800단계 부드러운 보간
- 3pt 선 두께

**노드 (Crossing Points):**
- 검은색 원형 마커
- 반지름: 3.5pt
- 교차점에 정확히 배치

**염기쌍 막대 (Base Pair Rungs):**
- **좌측 막대**: 염기(A/T/G/C) 고유 색깔
  - A: 진한 빨강 (0.8, 0.2, 0.2)
  - T: 진한 파랑 (0.2, 0.4, 0.8)
  - G: 진한 초록 (0.2, 0.7, 0.2)
  - C: 진한 노랑 (0.9, 0.8, 0.1)
- **우측 막대**: 상보 염기 색깔
- **막대 두께**: 6pt
- **가운데 수소 결합**: 흰색 점선 (dash: [2, 2], 2pt)

**염기 라벨:**
- 양쪽 백본 외부에 A/T/G/C 표시
- 각 염기에 해당하는 색상으로 표시
- Caption 폰트, Bold 스타일

#### 5. 그룹 관리 시스템
- **그룹 크기**: 20개 염기쌍/그룹 (DNASceneManager.groupSize = 20)
- **현재 그룹 표시**: `currentGroup` 기반으로 20개씩 표시
- **시퀀스 인덱싱**: `startIndex = (currentGroup - 1) * 20`
- **3D Scene 분리**: Ladder2D 모드에서는 3D scene 업데이트 생략

#### 6. 색상 스킴 지원
- By Base (염기별 색상)
- Rainbow (무지개 그라데이션)
- Hydrophobic (소수성 구분)
- Structure (구조 기반)

### 수학적 구현

**사인 함수 (Backbone Curves):**
```swift
let extendedHeight = height * 1.2  // 20% 확장
let yOffset = (extendedHeight - height) / 2
let omega = CGFloat(K + 1) * .pi / extendedHeight

func xLeft(y: CGFloat) -> CGFloat {
    let normalizedY = y - yTop + yOffset
    return xCenter - xAmp * sin(omega * normalizedY)
}

func xRight(y: CGFloat) -> CGFloat {
    let normalizedY = y - yTop + yOffset
    return xCenter + xAmp * sin(omega * normalizedY)
}
```

**노드 위치:**
```swift
yNodes[j] = yTop + (j / (K + 1)) * height
```

**염기쌍 위치 (Half-step):**
```swift
for k in 0..<n_j {
    y = yStart + (k + 0.5) * ((yEnd - yStart) / n_j)
}
```

### 파일 구조

```
DNAViewer/Sources/Views/Ladder/
└── DNALadderView.swift
    ├── DNALadder2DInteractiveView (Main View)
    │   ├── State variables (N, K, height, showLabels, etc.)
    │   ├── currentGroupPairs (computed property)
    │   └── body with Canvas
    └── Helper Functions
        ├── complement(_ base: Character) -> Character
        └── baseColor(_ base: Character) -> Color
```

### 통합 및 연동

**ViewerView.swift:**
- `renderingView` computed property에서 `.ladder2D` 케이스 처리
- `DNALadder2DInteractiveView`를 `environmentObject(sceneManager)`와 함께 표시

**DNASceneManager.swift:**
- `groupSize = 20` 설정
- `loadSequence()` 및 `loadGroup()`에서 ladder2D 모드 시 3D scene 업데이트 스킵
- 그룹 계산 로직 최적화

### 결과

이제 Ladder 2D 스타일은:
- ✅ 과학적으로 정확한 2D DNA 사다리 표현
- ✅ 4번의 교차점이 명확하게 표시
- ✅ 균등하게 분배된 염기쌍 (끝단 가중치 0.5 반영)
- ✅ 실제 염기서열과 색상 표시
- ✅ 색상별로 구분된 염기쌍 막대 (좌/우)
- ✅ 흰색 점선 수소 결합 표시
- ✅ 그룹 네비게이션 (20개씩) 완전 연동
- ✅ 색상 스킴 완전 연동
- ✅ 3D 렌더링과 완전 분리된 2D Canvas 렌더링

---

## Ladder & Genome Map Implementation Plan

### 1. 데이터 모델 확장
- [x] `DNASequence` 혹은 관련 ViewModel에 `BasePair`, `GeneMark` 컬렉션을 노출할 계산 속성/캐시 추가
- [ ] 유전자/마커 메타데이터를 가져오는 데이터 소스(예: JSON, API, CoreData) 정의
- [ ] `GeneMark` 색상 팔레트와 타입(enum) 설계 (예: 기본 유전자, 변이, CpG 등)

### 2. Ladder 뷰 (2D 사다리)
1. **뷰 생성**
   - [x] `DNALadderView` SwiftUI 뷰를 `Sources/Views/Ladder` 폴더에 추가
   - [x] `Canvas` 기반 렌더링 코드 구현 (백본·가로 막대·문자)
2. **상호작용**
   - [x] 스크롤 & 핀치 확대를 위해 `ScrollView` + `MagnificationGesture` 통합
   - [ ] 선택/탭 제스처로 특정 base pair 하이라이트 기능 고려
3. **테마/Legend**
   - [x] 색상 레전드 컴포넌트 (`LegendView`) 작성 및 UI 배치
   - [x] 다크모드 대비 색상 대비 검토

### 3. Genome Map 뷰 (선형 지도)
1. **레이아웃**
   - [x] `GenomeMapView` SwiftUI 뷰 추가
   - [x] `GeometryReader` 기반으로 전체 길이 대비 위치 비율 계산
   - [x] 스크롤 영역 및 Zoom 컨트롤 구성
2. **마커 렌더링**
   - [x] `GeneMark` 리스트를 통해 `RoundedRectangle` + 텍스트 배치
   - [x] 마커 최소 길이 보정 및 오버랩 처리 로직 추가 (예: offset stack, small bump)
3. **툴팁/Popover**
   - [x] 마커 탭 시 좌표, 설명, 기능 링크를 포함한 팝오버/시트 표시
   - [x] iOS/macOS 별 적절한 프레젠테이션 방식(if #available)

### 4. 뷰 통합
- [x] 기존 `DNAViewer` UI에 스타일 전환 토글 추가 (`Ladder`, `Map`, `Double Helix`, ...)
- [x] ViewModel에 선택된 스타일 상태(`@Published var representation`)와 필요한 데이터 공급
- [x] `DNASceneManager`와 2D 뷰 간 전환 시 애니메이션/상태 유지 검토

### 5. 데이터 준비 & 시나리오
- [x] 샘플 시퀀스/유전자 데이터 세트 작성 (Chromosome 17, BRCA1/TP53 등)
- [x] 긴 염기서열 테스트 (성능/메모리 확인)
- [x] 없는 데이터(예: start/end 미정) 처리 규칙 정의

### 6. 기능 확장 로드맵
- [ ] **툴팁 강화**: GeneMark 구조에 설명/ClinVar 링크 추가, popover에서 상세 정보 표시
- [ ] **멀티 트랙**: 변이, CpG, 제한효소 사이트를 개별 트랙으로 렌더 (Stacked layout)
- [ ] **Swift Charts 연동**: GC content, coverage 라인 차트 및 히트맵 오버레이
- [ ] **공유/Export**: Ladder/Map 뷰를 이미지로 캡처해 저장/공유 기능 구현

### 7. 테스트 & 검증
- [x] SwiftUI Snapshot 테스트 또는 스크린샷 비교
- [x] 유닛 테스트: BasePair 상보성, GeneMark 정렬/비율 계산 검증
- [x] 접근성 체크: Dynamic Type, VoiceOver 라벨링

### 8. 문서화
- [x] README 섹션 업데이트: 새 스타일 소개, 스크린샷
- [x] 코드 주석 및 아키텍처 설명 추가
- [ ] 차후 기여자용 개발 가이드 작성

---

### 작업 순서 제안 (Milestones)

1. **MVP**: `DNALadderView` + `GenomeMapView` 기본 렌더링, 샘플 데이터 연결 ✅
2. **Interaction**: 줌/팬, 마커 선택, 뷰 전환 UI ✅
3. **Enhancement**: 툴팁, 멀티 트랙, Charts 통합 (진행 중)
4. **Polish**: 접근성, 성능 튜닝, 문서화 & 테스트 ✅

---

## 최근 업데이트 (2025-01-22)

### 염기쌍 시각화 개선
- 염기쌍 막대를 좌우로 분리하여 각 염기 색깔 표시
- 가운데 흰색 점선으로 수소 결합 표시
- 백본 색상을 보라색으로 변경
- 막대 두께를 6pt로 증가하여 가독성 향상
- 노드 크기를 3.5pt로 조정

### 그룹 크기 일관성 확보
- DNASceneManager의 groupSize를 20으로 통일
- DNALadderView가 sceneManager.groupSize를 동적으로 사용
- 모든 그룹에서 일관되게 20개 염기쌍 표시
- 3D scene과 2D ladder 렌더링 완전 분리
