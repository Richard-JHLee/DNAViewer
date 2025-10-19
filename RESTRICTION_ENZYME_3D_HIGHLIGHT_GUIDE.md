# Restriction Enzyme 3D Highlight 기능 가이드

## 📋 개요

Bottom menu에서 **Scissor** 버튼 선택 → 효소 선택 → **Show 3D** 버튼 클릭 시, 메인화면으로 이동하여 **해당 그룹의 염기서열에서 절단 위치를 highlight**하는 기능이 완전히 구현되었습니다.

---

## 🔧 주요 구현 사항

### **✅ Step 1: Show 3D 버튼 자동 분석**

**기능**: Show 3D 버튼 클릭 시 자동으로 염기서열 분석 수행

```swift
private func highlightCutSites() {
    print("🎯 Show 3D button clicked")
    
    // 분석이 안 되어 있으면 먼저 분석
    if restrictionMap == nil {
        print("⚠️ No restriction map - analyzing sequence first...")
        analyzeSequence()
    }
    
    // Cut positions 수집 및 정렬
    var cutPositions: [Int] = []
    for (enzyme, sites) in map.hits {
        cutPositions.append(contentsOf: sites.map { $0.position })
    }
    cutPositions.sort()
    
    // 3D 화면에서 highlight
    sceneManager.highlightPositions(cutPositions)
    dismiss()
}
```

**개선 사항**:
- ✅ "Analyze" 버튼을 누르지 않아도 자동 분석
- ✅ 상세한 디버깅 로그 출력
- ✅ 효소별 절단 위치 추적
- ✅ 영향받는 그룹 계산

---

### **✅ Step 2: 3D 화면 Highlight 시각화 개선**

**기능**: 절단 위치를 더 명확하게 표시

#### **이중 마커 시스템**:

1. **빨간색 절단면 (Red Cutting Plane)**
   ```swift
   let cutPlane = SCNBox(width: 4.0, height: 0.2, length: 4.0, chamferRadius: 0.1)
   cutPlane.firstMaterial?.diffuse.contents = PlatformColor.red
   cutPlane.firstMaterial?.emission.contents = PlatformColor.red  // 빛나는 효과
   cutPlane.firstMaterial?.transparency = 0.7
   ```

2. **노란색 구체 마커 (Yellow Sphere Marker)**
   ```swift
   let sphere = SCNSphere(radius: 0.8)
   sphere.firstMaterial?.diffuse.contents = PlatformColor.yellow
   sphere.firstMaterial?.emission.contents = PlatformColor.yellow
   sphere.firstMaterial?.transparency = 0.8
   sphereMarker.position = SCNVector3(0, 2.0, 0)  // DNA 위에 위치
   ```

#### **애니메이션 효과**:

1. **깜빡임 애니메이션**:
   ```swift
   let fadeOut = SCNAction.fadeOpacity(to: 0.3, duration: 0.4)
   let fadeIn = SCNAction.fadeOpacity(to: 1.0, duration: 0.4)
   let flash = SCNAction.sequence([fadeOut, fadeIn])
   let repeatFlash = SCNAction.repeatForever(flash)
   ```

2. **펄스 애니메이션**:
   ```swift
   let scaleUp = SCNAction.scale(to: 1.2, duration: 0.4)
   let scaleDown = SCNAction.scale(to: 1.0, duration: 0.4)
   let pulse = SCNAction.sequence([scaleUp, scaleDown])
   let repeatPulse = SCNAction.repeatForever(pulse)
   ```

---

### **✅ Step 3: SequenceBar에 절단 위치 표시**

**기능**: 염기서열 바에서 절단 위치를 시각적으로 표시

#### **절단 위치 아이콘**:
```swift
if isCutSite {
    Image(systemName: "scissors.circle.fill")
        .font(.system(size: 10))
        .foregroundColor(.red)
}
```

#### **빨간색 테두리**:
```swift
private var borderColor: Color {
    if isCutSite {
        return .red  // 절단 위치: 빨간색
    } else if isSelected {
        return .blue  // 선택: 파란색
    } else if isInCurrentGroup {
        return .white  // 현재 그룹: 흰색
    }
}
```

#### **Cut Site 체크**:
```swift
private func isCutSite(_ index: Int) -> Bool {
    return sceneManager.highlightedCutSites.contains(index)
}
```

---

### **✅ Step 4: 그룹 간 Navigation 개선**

**기능**: 여러 그룹에 걸쳐 있는 절단 위치를 스마트하게 처리

#### **그룹 계산 및 Navigation**:
```swift
func highlightPositions(_ positions: [Int]) {
    highlightedCutSites = positions.sorted()
    
    // 그룹별 절단 위치 계산
    var groupsWithCutSites: [Int: [Int]] = [:]
    for position in highlightedCutSites {
        let group = (position / groupSize) + 1
        if groupsWithCutSites[group] == nil {
            groupsWithCutSites[group] = []
        }
        groupsWithCutSites[group]?.append(position)
    }
    
    let affectedGroups = groupsWithCutSites.keys.sorted()
    print("📊 Cut sites span \(affectedGroups.count) groups: \(affectedGroups)")
    
    // 첫 번째 그룹으로 자동 이동
    let firstGroup = affectedGroups.first ?? currentGroup
    if firstGroup != currentGroup {
        loadGroup(firstGroup)
        // 그룹 로드 후 highlight
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.highlightPositionsInCurrentGroup(self.highlightedCutSites)
        }
    }
}
```

**개선 사항**:
- ✅ 절단 위치가 여러 그룹에 걸쳐 있어도 자동 처리
- ✅ 첫 번째 절단 위치가 있는 그룹으로 자동 이동
- ✅ 그룹 변경 후 자동으로 highlight
- ✅ 카메라 자동 포커싱

---

## 🎯 사용자 워크플로우

### **전체 시나리오**

```
1. Gene Library → Gene 선택 (예: BRCA1)
   ↓
2. Apply → 메인화면에 DNA 3D 구조 표시
   ↓
3. Bottom Menu → Scissor 버튼 클릭
   ↓
4. Restriction Enzyme View 열림
   - 자동으로 염기서열 분석 시작
   - 사용 가능한 효소 목록 표시
   ↓
5. 효소 선택 (예: EcoRI, BamHI)
   - 각 효소별 매칭 사이트 개수 표시
   ↓
6. Show 3D 버튼 클릭
   ↓
7. 메인화면으로 자동 이동
   - 절단 위치가 있는 첫 번째 그룹으로 이동
   - 3D 구조에서 절단 위치 highlight
   - SequenceBar에서 절단 위치 표시
   - 카메라 자동 포커싱
```

---

## 🧪 테스트 시나리오

### **Scenario 1: BRCA1 + EcoRI (단일 효소)**

**Step 1**: BRCA1 gene 선택 및 Apply
```
Sequence length: 7,088 bp
Total groups: 71 groups (100 bp/group)
```

**Step 2**: Scissor 버튼 클릭
```
🧬 Analyzing sequence for available restriction enzymes...
✅ EcoRI: 2 sites found
```

**Step 3**: EcoRI 선택
```
✂️ Enzyme: EcoRI
   - Cut site at position: 1234
   - Cut site at position: 4567
```

**Step 4**: Show 3D 버튼 클릭

**예상 결과**:
```
📊 Total cut sites: 2
📊 Cut positions: [1234, 4567]
📊 Affected groups: [13, 46]
🎯 Navigating to first group with cut sites: G13
```

**메인화면**:
- ✅ 자동으로 Group 13으로 이동
- ✅ Position 1234에 빨간 절단면 + 노란 구체 표시
- ✅ SequenceBar에서 Position 1234에 ✂️ 아이콘 표시
- ✅ 카메라가 절단 위치에 포커싱

---

### **Scenario 2: TP53 + 다중 효소 (EcoRI + BamHI)**

**Step 1**: TP53 gene 선택 (2,512 bp, 26 groups)

**Step 2**: EcoRI, BamHI 선택
```
✅ EcoRI: 1 sites found
✅ BamHI: 2 sites found
Total: 3 cut sites
```

**Step 3**: Show 3D 버튼 클릭

**예상 결과**:
```
📊 Total cut sites: 3
📊 Enzymes used: EcoRI, BamHI
📊 Cut positions: [456, 1123, 2045]
📊 Affected groups: [5, 12, 21]
```

**메인화면**:
- ✅ Group 5로 자동 이동
- ✅ 3개의 절단 위치 모두 highlight (그룹 이동 시마다)
- ✅ SequenceBar에서 현재 그룹의 절단 위치 표시

---

### **Scenario 3: 그룹 간 Navigation 테스트**

**초기 상태**: Group 1 표시 중

**Step 1**: EcoRI 선택 (Position 1234 = Group 13)

**Step 2**: Show 3D 클릭

**예상 동작**:
```
🔄 Loading group 13...
   ↓ (0.3초 대기)
🎨 Highlighting positions in group 13
✂️ Adding cut site marker at position 1234
   ✅ Added plane and sphere markers
   📹 This is the first cut site - focusing camera
```

**결과**:
- ✅ Group 1 → Group 13 자동 이동
- ✅ Position 1234 highlight
- ✅ SequenceBar 업데이트 (Group 13 시퀀스 표시)
- ✅ 카메라 포커싱

---

### **Scenario 4: SequenceBar Cut Site 표시 테스트**

**Group 13에서 Position 1234에 절단 위치가 있을 때**:

**SequenceBar 표시**:
```
Position: 1200  |  7088 bp
[G1] [G2] ... [G13] ... [G71]
        ↑ (파란색 강조)

Sequence:
... A T G [C] G A T C ...
        ↑
     (빨간 테두리 + ✂️ 아이콘)
```

**BaseCell 특징**:
- ✅ Position 1234: 빨간 테두리 (3px)
- ✅ 위에 ✂️ 빨간 아이콘
- ✅ 클릭 시 해당 위치로 포커싱

---

## 📊 시각적 표시 요약

### **3D 화면**

| 요소 | 색상 | 크기 | 애니메이션 |
|------|------|------|------------|
| 절단면 | 빨강 | 4.0 x 0.2 x 4.0 | 깜빡임 (0.3-1.0) |
| 구체 마커 | 노랑 | 반지름 0.8 | 깜빡임 + 펄스 (1.0-1.2) |
| 위치 | DNA 중심 + 위쪽 2.0 | - | - |

### **SequenceBar**

| 상태 | 표시 | 색상 | 테두리 |
|------|------|------|--------|
| 절단 위치 | ✂️ 아이콘 | 빨강 | 3px 빨강 |
| 선택됨 | - | 기본 | 3px 파랑 |
| 현재 그룹 | - | 기본 | 2px 흰색 |
| 일반 | - | 기본 | 없음 |

---

## 🔍 디버깅 로그 예시

### **Show 3D 버튼 클릭 시**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Show 3D button clicked
✂️ Enzyme: EcoRI
   - Cut site at position: 1234
   - Cut site at position: 4567
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Total cut sites: 2
📊 Enzymes used: EcoRI
📊 Cut positions: [1234, 4567]
📊 Affected groups: [13, 46]
🎬 Highlighting cut sites in 3D view...
✅ Highlight complete - dismissing enzyme view
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### **DNASceneManager Highlight 시**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✂️ Highlighting 2 cut sites
📍 Positions: [1234, 4567]
📊 Cut sites span 2 groups: [13, 46]
🎯 Navigating to first group with cut sites: G13
🔄 Loading group 13...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### **Marker 추가 시**:
```
✂️ Adding cut site marker at position 1234
   ✅ Added plane and sphere markers
   📹 This is the first cut site - focusing camera
📹 Focusing camera on position: (12.5, 3.2, 15.0)
📹 Moving camera to: (12.5, 8.2, 35.0)
✅ Camera focused
```

### **Highlight 제거 시**:
```
🧹 Clearing all highlights and cut site markers
   Cleared 2 tracked cut sites
   Removed 4 marker nodes
✅ Highlights cleared
```

---

## 🎨 코드 아키텍처

### **데이터 흐름**

```
RestrictionEnzymeView
  ↓ (사용자가 효소 선택)
selectedEnzymes: Set<RestrictionEnzyme>
  ↓ (Show 3D 클릭)
analyzeSequence() → restrictionMap
  ↓
highlightCutSites() → cutPositions: [Int]
  ↓
sceneManager.highlightPositions(cutPositions)
  ↓
┌─────────────────────────────────┐
│ DNASceneManager                 │
│  - highlightedCutSites: [Int]   │
│  - calculateAffectedGroups()    │
│  - loadGroup(firstGroup)        │
│  - highlightPositionsInCurrentGroup() │
│  - addCutSiteMarker()           │
└─────────────────────────────────┘
  ↓
┌─────────────────────────────────┐
│ SequenceBar                     │
│  - isCutSite(index)             │
│  - BaseCell(isCutSite: true)    │
└─────────────────────────────────┘
```

### **주요 메서드**

#### **RestrictionEnzymeView.swift**:
- `highlightCutSites()`: Show 3D 버튼 액션
- `analyzeSequence()`: 효소 분석
- `createFragmentsFromCutSites()`: 절단 프래그먼트 생성

#### **DNASceneManager.swift**:
- `highlightPositions(_ positions: [Int])`: 다중 위치 highlight
- `highlightPositionsInCurrentGroup(_ positions: [Int])`: 현재 그룹 highlight
- `addCutSiteMarker(to node: SCNNode, at position: Int)`: 마커 추가
- `clearHighlights()`: 모든 highlight 제거

#### **SequenceBar.swift**:
- `isCutSite(_ index: Int) -> Bool`: 절단 위치 체크
- `BaseCell`: 개별 염기 셀 (cut site 표시 포함)

---

## 🚀 고급 기능

### **1. 다중 그룹 Navigation**

절단 위치가 여러 그룹에 걸쳐 있을 때:
```swift
// Group 13, 24, 46에 절단 위치가 있을 때
affectedGroups = [13, 24, 46]

// 첫 번째 그룹(13)으로 자동 이동
loadGroup(13)

// 사용자가 Group 24로 이동하면
// 해당 그룹의 절단 위치도 자동 highlight
```

### **2. 카메라 자동 포커싱**

첫 번째 절단 위치에 카메라 포커싱:
```swift
if position == highlightedCutSites.first {
    focusCameraOn(position: node.worldPosition)
}
```

### **3. 실시간 업데이트**

그룹 변경 시 SequenceBar 자동 업데이트:
```swift
.onChange(of: sceneManager.currentGroup) { newGroup in
    // SequenceBar가 자동으로 새로운 그룹의 시퀀스 표시
    // 해당 그룹의 절단 위치도 자동 표시
}
```

---

## 📝 테스트 체크리스트

### **기본 기능**
- [ ] Scissor 버튼 클릭 시 restriction enzyme view 표시
- [ ] 효소 선택 후 Show 3D 버튼 활성화
- [ ] Show 3D 클릭 시 메인화면으로 이동
- [ ] 절단 위치가 3D에서 highlight됨

### **3D Highlight**
- [ ] 빨간 절단면 표시
- [ ] 노란 구체 마커 표시
- [ ] 깜빡임 애니메이션 작동
- [ ] 펄스 애니메이션 작동
- [ ] 카메라 자동 포커싱

### **SequenceBar 표시**
- [ ] 절단 위치에 ✂️ 아이콘 표시
- [ ] 빨간 테두리 표시
- [ ] 현재 그룹의 절단 위치만 표시
- [ ] 그룹 변경 시 업데이트

### **그룹 Navigation**
- [ ] 절단 위치가 있는 첫 번째 그룹으로 자동 이동
- [ ] 여러 그룹에 걸친 절단 위치 처리
- [ ] 그룹 변경 후 자동 highlight
- [ ] SequenceBar 그룹 버튼 동기화

### **다중 효소 테스트**
- [ ] 2개 이상의 효소 선택
- [ ] 모든 절단 위치 표시
- [ ] 효소별 구분 (현재는 통합)
- [ ] 다중 그룹 처리

### **엣지 케이스**
- [ ] 효소를 선택하지 않고 Show 3D 클릭 (비활성화)
- [ ] 절단 위치가 없는 효소 선택
- [ ] 첫 번째 그룹에 절단 위치
- [ ] 마지막 그룹에 절단 위치
- [ ] 그룹 경계에 절단 위치

---

## 💡 추가 개선 가능 사항

### **1. 효소별 색상 구분**
```swift
// 각 효소마다 다른 색상으로 표시
EcoRI → Red
BamHI → Blue
HindIII → Green
```

### **2. 절단 정보 오버레이**
```swift
// 절단 위치에 효소 이름 표시
cutMarkerLabel.text = "EcoRI\nPosition: 1234"
```

### **3. 절단 위치 간 Navigation**
```swift
// Next/Previous 버튼으로 절단 위치 간 이동
navigateToNextCutSite()
navigateToPreviousCutSite()
```

### **4. 애니메이션 개선**
```swift
// 절단 애니메이션 (DNA가 실제로 잘리는 효과)
animateDNACutting(at: position)
```

---

## 📚 참고 자료

### **SceneKit 관련**
- **SCNAction**: 노드 애니메이션
- **SCNMaterial**: 재질 및 발광 효과
- **SCNCamera**: 카메라 포커싱

### **SwiftUI 관련**
- **@ObservedObject**: 상태 동기화
- **ScrollViewReader**: 스크롤 위치 제어
- **.onChange()**: 상태 변경 감지

### **Restriction Enzymes**
- **NCBI E-utilities**: 효소 데이터베이스
- **REBASE**: Restriction enzyme 정보

---

**작성일**: 2025-10-19  
**버전**: v1.0  
**테스트 환경**: iOS 16.0+, Xcode 15.0+


