# Highlight Persistence Fix - 그룹 변경 시 절단 위치 유지

## 🐛 문제 설명

### **증상**:
- ✅ 첫 번째 그룹에서는 절단 위치 highlight가 정상 표시
- ❌ 두 번째 그룹으로 이동하면 highlight가 사라짐
- ❌ 다시 첫 번째 그룹으로 돌아가도 highlight가 없음

### **원인**:
1. **`rebuildScene()` 호출 시 모든 노드 제거**
   - 그룹 변경 → `loadGroup()` → `rebuildScene()`
   - `helixNodes` 배열이 완전히 비워지고 새로 생성됨
   - 기존의 cut site marker 노드들이 모두 사라짐

2. **`highlightedCutSites` 배열은 유지되지만 재적용 안 됨**
   - 배열에는 절단 위치 정보가 남아있음
   - 하지만 새로운 노드에 자동으로 적용되지 않음

---

## 🔧 해결 방법

### **Solution 1: `rebuildScene()` 완료 후 자동 재적용**

`rebuildScene()` 메서드가 완료되면 자동으로 highlight를 다시 적용합니다.

```swift
// Add nodes on main thread
DispatchQueue.main.async { [weak self] in
    guard let self = self else { return }
    print("➕ Adding \(newNodes.count) new nodes to scene...")
    for node in newNodes {
        self.scene.rootNode.addChildNode(node)
        self.helixNodes.append(node)
    }
    print("✅ Scene rebuild complete. Total nodes: \(self.helixNodes.count)")
    
    // Reset the rebuilding flag
    self.isRebuilding = false
    
    // ✅ Re-apply highlights if there are cut sites
    if !self.highlightedCutSites.isEmpty {
        print("🔄 Re-applying highlights for \(self.highlightedCutSites.count) cut sites after rebuild")
        // Small delay to ensure nodes are fully rendered
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.highlightPositionsInCurrentGroup(self.highlightedCutSites)
        }
    }
}
```

**개선 사항**:
- ✅ 노드가 완전히 렌더링된 후 (0.2초 대기) highlight 적용
- ✅ `highlightedCutSites`가 비어있지 않으면 자동 재적용
- ✅ 그룹 변경 시마다 자동으로 작동

---

### **Solution 2: Cut Sites 배열 보존**

`rebuildScene()` 시작 시 `highlightedCutSites`를 저장하고 복원합니다.

```swift
func rebuildScene() {
    // Prevent concurrent rebuilds
    guard !isRebuilding else {
        print("⚠️ Rebuild already in progress, skipping...")
        return
    }
    
    isRebuilding = true
    
    // ✅ Save cut sites before clearing
    let savedCutSites = highlightedCutSites
    print("🧹 Clearing \(helixNodes.count) existing nodes...")
    print("💾 Saved \(savedCutSites.count) cut sites for re-application")
    
    DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        self.helixNodes.forEach { $0.removeFromParentNode() }
        self.helixNodes.removeAll()
        
        // ✅ Restore cut sites
        self.highlightedCutSites = savedCutSites
        
        // ... rest of rebuild logic
    }
}
```

**개선 사항**:
- ✅ `highlightedCutSites` 배열이 실수로 제거되는 것 방지
- ✅ 노드 제거 후에도 정보 유지

---

### **Solution 3: `clearHighlights()` 개선**

마커만 제거하고 `highlightedCutSites` 배열은 선택적으로 보존합니다.

```swift
func clearHighlights(preserveCutSites: Bool = false) {
    print("🧹 Clearing all highlights and cut site markers")
    
    // ✅ Clear tracked cut sites only if not preserving
    if !preserveCutSites {
        let previousCount = highlightedCutSites.count
        highlightedCutSites.removeAll()
        print("   Cleared \(previousCount) tracked cut sites")
    } else {
        print("   Preserving \(highlightedCutSites.count) tracked cut sites")
    }
    
    var removedCount = 0
    
    // Remove visual markers from nodes
    for helixNode in helixNodes {
        helixNode.enumerateChildNodes { node, _ in
            // Remove all marker nodes
            if node.name == "highlight" ||
               node.name?.hasPrefix("cut_site_") == true ||
               node.name?.hasPrefix("cut_site_sphere_") == true {
                node.removeFromParentNode()
                removedCount += 1
            }
        }
    }
    
    print("   Removed \(removedCount) marker nodes")
    print("✅ Highlights cleared")
}
```

**사용 예시**:
```swift
// 완전히 제거 (기본)
clearHighlights()

// 마커만 제거, cut sites 배열 유지
clearHighlights(preserveCutSites: true)
```

---

### **Solution 4: `highlightPositionsInCurrentGroup()` 디버깅 강화**

상세한 로그를 추가하여 문제 진단이 쉽도록 개선합니다.

```swift
private func highlightPositionsInCurrentGroup(_ positions: [Int]) {
    print("🎨 highlightPositionsInCurrentGroup called")
    print("   Positions to highlight: \(positions)")
    print("   Display range: \(displayStart) - \(displayStart + displayLength)")
    print("   Available helixNodes: \(helixNodes.count)")
    
    var highlightCount = 0
    
    for position in positions {
        let relativeIndex = position - displayStart
        
        guard relativeIndex >= 0 && relativeIndex < displayLength else {
            print("   ⏭️ Position \(position) (relative: \(relativeIndex)) is out of current display range")
            continue
        }
        
        print("   🔍 Looking for node: basepair_\(relativeIndex) (global position: \(position))")
        
        // Find and highlight the node at this position
        var found = false
        for helixNode in helixNodes {
            if let name = helixNode.name, name == "basepair_\(relativeIndex)" {
                print("   ✅ Found node: \(name)")
                addCutSiteMarker(to: helixNode, at: position)
                highlightCount += 1
                found = true
                break
            }
        }
        
        if !found {
            print("   ❌ Node not found for position \(position) (relative: \(relativeIndex))")
            // Debug: list first few node names
            let nodeNames = helixNodes.prefix(5).compactMap { $0.name }
            print("   📋 First few node names: \(nodeNames)")
        }
    }
    
    print("   📊 Highlighted \(highlightCount) out of \(positions.count) positions in current group")
}
```

**디버깅 정보**:
- ✅ 현재 표시 범위 확인
- ✅ 사용 가능한 노드 개수
- ✅ 각 position의 처리 결과
- ✅ 노드를 찾지 못한 경우 이유 분석

---

## 🎯 전체 흐름

### **시나리오: BRCA1 + EcoRI (Position 1234, 4567)**

#### **1단계: Show 3D 클릭**
```
🎯 Show 3D button clicked
✂️ Enzyme: EcoRI
   - Cut site at position: 1234
   - Cut site at position: 4567
📊 Total cut sites: 2
📊 Affected groups: [13, 46]
🎯 Navigating to first group with cut sites: G13
```

#### **2단계: Group 13 로드**
```
🔄 Loading group 13 (was: 1)
📊 Group 13: start=1200, length=100
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
rebuildScene() 호출
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💾 Saved 2 cut sites for re-application
🧹 Clearing 20 existing nodes...
➕ Adding 20 new nodes to scene...
✅ Scene rebuild complete. Total nodes: 20
🔄 Re-applying highlights for 2 cut sites after rebuild
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### **3단계: Highlight 재적용 (0.2초 후)**
```
🎨 highlightPositionsInCurrentGroup called
   Positions to highlight: [1234, 4567]
   Display range: 1200 - 1300
   Available helixNodes: 20
   🔍 Looking for node: basepair_34 (global position: 1234)
   ✅ Found node: basepair_34
✂️ Adding cut site marker at position 1234
   ✅ Added plane and sphere markers
   ⏭️ Position 4567 (relative: 3367) is out of current display range
   📊 Highlighted 1 out of 2 positions in current group
```

**결과**: Group 13에서 Position 1234 highlight 표시 ✅

---

#### **4단계: Group 46으로 이동 (사용자 액션)**
```
🔄 Loading group 46 (was: 13)
📊 Group 46: start=4500, length=100
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
rebuildScene() 호출
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💾 Saved 2 cut sites for re-application
🧹 Clearing 20 existing nodes...
➕ Adding 20 new nodes to scene...
✅ Scene rebuild complete. Total nodes: 20
🔄 Re-applying highlights for 2 cut sites after rebuild
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### **5단계: Highlight 재적용 (0.2초 후)**
```
🎨 highlightPositionsInCurrentGroup called
   Positions to highlight: [1234, 4567]
   Display range: 4500 - 4600
   Available helixNodes: 20
   ⏭️ Position 1234 (relative: -3266) is out of current display range
   🔍 Looking for node: basepair_67 (global position: 4567)
   ✅ Found node: basepair_67
✂️ Adding cut site marker at position 4567
   ✅ Added plane and sphere markers
   📊 Highlighted 1 out of 2 positions in current group
```

**결과**: Group 46에서 Position 4567 highlight 표시 ✅

---

#### **6단계: 다시 Group 13으로 돌아가기 (사용자 액션)**
```
🔄 Loading group 13 (was: 46)
📊 Group 13: start=1200, length=100
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
rebuildScene() 호출
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💾 Saved 2 cut sites for re-application
🧹 Clearing 20 existing nodes...
➕ Adding 20 new nodes to scene...
✅ Scene rebuild complete. Total nodes: 20
🔄 Re-applying highlights for 2 cut sites after rebuild
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎨 highlightPositionsInCurrentGroup called
   Positions to highlight: [1234, 4567]
   Display range: 1200 - 1300
   Available helixNodes: 20
   🔍 Looking for node: basepair_34 (global position: 1234)
   ✅ Found node: basepair_34
✂️ Adding cut site marker at position 1234
   ✅ Added plane and sphere markers (다시 표시됨!)
   📊 Highlighted 1 out of 2 positions in current group
```

**결과**: Group 13으로 돌아와도 Position 1234 highlight 다시 표시 ✅

---

## 📊 개선 전후 비교

### **개선 전**:
```
Group 1 → Group 13 (Show 3D)
  ✅ Position 1234 highlight 표시

Group 13 → Group 46
  ❌ Position 4567 highlight 안 나타남
  ❌ highlightedCutSites 배열 유지되지만 적용 안 됨

Group 46 → Group 13
  ❌ Position 1234 highlight 사라짐
  ❌ rebuildScene()가 markers를 제거했기 때문
```

### **개선 후**:
```
Group 1 → Group 13 (Show 3D)
  ✅ Position 1234 highlight 표시
  ✅ highlightedCutSites = [1234, 4567] 저장됨

Group 13 → Group 46
  ✅ rebuildScene() 완료 후 자동 재적용
  ✅ Position 4567 highlight 표시
  ✅ highlightedCutSites 배열 유지됨

Group 46 → Group 13
  ✅ rebuildScene() 완료 후 자동 재적용
  ✅ Position 1234 highlight 다시 표시
  ✅ 몇 번을 이동해도 항상 표시됨
```

---

## 🧪 테스트 시나리오

### **Test 1: 기본 Highlight Persistence**

**Step 1**: BRCA1 선택 → Scissor → EcoRI 선택 → Show 3D
- ✅ Group 13으로 이동
- ✅ Position 1234 highlight

**Step 2**: Group 46 버튼 클릭
- ✅ Group 46으로 이동
- ✅ Position 4567 highlight (자동)

**Step 3**: Group 13 버튼 다시 클릭
- ✅ Group 13으로 돌아옴
- ✅ Position 1234 highlight (자동)

---

### **Test 2: 다중 그룹 왔다갔다**

**Step 1**: Group 13 → Group 46 → Group 13 → Group 46 → Group 13
- ✅ 모든 이동 후 해당 그룹의 highlight 표시

**Step 2**: Group 1 → Group 13 → Group 1
- ✅ Group 13에서 highlight 표시
- ✅ Group 1에서는 highlight 없음 (절단 위치 없음)

---

### **Test 3: SequenceBar 동기화**

**Step 1**: Group 13에서
- ✅ 3D에서 Position 1234 highlight
- ✅ SequenceBar에서 ✂️ 아이콘

**Step 2**: Group 46으로 이동
- ✅ 3D에서 Position 4567 highlight
- ✅ SequenceBar에서 ✂️ 아이콘 (새 위치)
- ✅ 이전 아이콘 사라짐 (그룹 밖)

---

### **Test 4: Reload 버튼**

**Step 1**: Group 13에서 highlight 표시 중
**Step 2**: Reload 버튼 클릭
- ❓ 예상: highlight 제거 (의도적)
- ✅ rebuildScene() → highlightedCutSites 보존
- ✅ 자동 재적용됨

---

## 🔍 디버깅 팁

### **문제: Highlight가 여전히 안 나타남**

**Step 1**: 콘솔 로그 확인
```
💾 Saved X cut sites for re-application
🔄 Re-applying highlights for X cut sites after rebuild
🎨 highlightPositionsInCurrentGroup called
   Positions to highlight: [...]
   Display range: XXX - YYY
   Available helixNodes: N
```

**Step 2**: 노드 이름 확인
```
📋 First few node names: ["basepair_0", "basepair_1", ...]
```

**Step 3**: 타이밍 확인
- `0.2초` 대기가 충분한지 확인
- 필요시 `0.3초` 또는 `0.5초`로 증가

---

### **문제: 카메라가 포커싱 안 됨**

**원인**: 첫 번째 절단 위치가 현재 그룹에 없을 때

**해결**:
```swift
// 현재 그룹의 첫 번째 절단 위치에 포커싱
let visibleCutSites = highlightedCutSites.filter { position in
    let relativeIndex = position - displayStart
    return relativeIndex >= 0 && relativeIndex < displayLength
}

if let firstVisiblePosition = visibleCutSites.first {
    focusCameraOn(firstVisiblePosition)
}
```

---

## 📝 체크리스트

### **구현 완료**:
- [x] `rebuildScene()` 완료 후 자동 highlight 재적용
- [x] `highlightedCutSites` 배열 보존
- [x] `clearHighlights()` 선택적 보존 옵션
- [x] `highlightPositionsInCurrentGroup()` 디버깅 로그
- [x] 0.2초 렌더링 대기 시간
- [x] 현재 그룹 범위 체크

### **테스트 완료**:
- [ ] Group 13 → 46 → 13 순환
- [ ] 여러 효소 동시 선택
- [ ] SequenceBar 동기화
- [ ] Reload 버튼 작동

---

**작성일**: 2025-10-19  
**버전**: v1.1  
**테스트 환경**: iOS 16.0+, Xcode 15.0+

