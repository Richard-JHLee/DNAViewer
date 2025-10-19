# Restriction Enzyme 기능 개선 가이드

## 📋 개요

Bottom menu에서 **Scissor** 버튼을 클릭하면 현재 메인화면의 염기서열에서 **restriction enzymes 효소로 가능한 것을 리스트로 보여주는** 기능이 개선되었습니다.

---

## 🔧 주요 개선 사항

### **✅ Step 1: 현재 염기서열에서 사용 가능한 효소만 표시**

**기존**: 모든 restriction enzyme을 표시 (매칭 여부 관계없이)

**개선**: 현재 염기서열과 매칭되는 효소만 표시

```swift
@State private var availableEnzymes: [RestrictionEnzyme] = []
@State private var enzymeSiteCounts: [String: Int] = [:]
@State private var showOnlyAvailable = true
```

---

### **✅ Step 2: 효소 분석 로직 개선**

**새로운 기능**: 앱 시작 시 자동으로 염기서열 분석

```swift
private func analyzeSequenceForAvailableEnzymes() {
    let analyzer = RestrictionSiteAnalyzer()
    let allEnzymes = RestrictionEnzyme.all
    let hitsDict = analyzer.analyze(sequence: sequence.sequence, enzymes: allEnzymes)
    
    // 매칭되는 효소만 필터링
    var available: [RestrictionEnzyme] = []
    for enzyme in allEnzymes {
        if let hits = hitsDict[enzyme.name] {
            available.append(enzyme)
            siteCounts[enzyme.name] = hits.count
        }
    }
}
```

---

### **✅ Step 3: UI 개선 - 사용 가능한 효소와 불가능한 효소 구분 표시**

**새로운 UI 요소**:

1. **필터 토글 버튼**: "Available Only" / "All Enzymes" 전환
2. **분석 상태 표시**: "Analyzing..." / "X available" 표시
3. **효소 상태 아이콘**: ✅ (사용 가능) / ❌ (사용 불가능)
4. **사이트 개수 표시**: "3 sites", "Available", "No match"

```swift
private var filterToggleView: some View {
    HStack {
        Button(action: { showOnlyAvailable.toggle() }) {
            HStack(spacing: 8) {
                Image(systemName: showOnlyAvailable ? "checkmark.circle.fill" : "circle")
                Text(showOnlyAvailable ? "Available Only" : "All Enzymes")
            }
        }
        
        Spacer()
        
        Text("\(availableEnzymes.count) available")
    }
}
```

---

### **✅ Step 4: 실시간 분석 - 효소 선택 시 즉시 매칭 사이트 개수 표시**

**개선된 EnzymeRow**:

```swift
struct EnzymeRow: View {
    let enzyme: RestrictionEnzyme
    let isSelected: Bool
    let siteCount: Int
    let isAvailable: Bool  // ← 새로 추가
    
    var body: some View {
        // 사용 가능한 효소: 밝게 표시, 사이트 개수 표시
        // 사용 불가능한 효소: 흐리게 표시, "No match" 표시
    }
}
```

---

### **✅ Step 5: 헤더 정보 개선**

**새로운 정보 표시**:

```swift
private var headerView: some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(sequence.name)
        Text("\(sequence.length) bp")
        
        // ← 새로 추가: 사용 가능한 효소 개수
        Text("\(availableEnzymes.count) available enzymes")
        
        // ← 새로 추가: 염기서열 미리보기
        Text("Preview: \(String(sequence.sequence.prefix(30)))...")
    }
}
```

---

## 🧪 테스트 시나리오

### **Scenario 1: BRCA1 염기서열 (7,088 bp)**

1. **Gene Library**에서 **BRCA1** 선택 및 Apply
2. **Bottom Menu**에서 **Scissor** 버튼 클릭
3. **예상 결과**:
   - 자동으로 염기서열 분석 시작 ("Analyzing...")
   - 분석 완료 후 사용 가능한 효소만 표시
   - 각 효소별 매칭 사이트 개수 표시

**콘솔 로그 예시**:
```
🧬 Analyzing sequence for available restriction enzymes...
📊 Sequence length: 7088 bp
📊 Sequence preview: GCTGAGACTTCCTGGACGGGGGACAGGCTGTGGGGTTTCTCAGATAACTGGGCCCCTGCGCTCAGGAGGC...
🔍 Testing 15 restriction enzymes...
✅ EcoRI: 2 sites found
✅ BamHI: 1 sites found
✅ HindIII: 3 sites found
❌ PstI: No sites found
📋 Found 8 available enzymes out of 15 total
```

### **Scenario 2: TP53 염기서열 (2,512 bp)**

1. **TP53** gene 선택 및 Apply
2. **Scissor** 버튼 클릭
3. **예상 결과**:
   - TP53 염기서열에 맞는 효소만 표시
   - BRCA1과 다른 효소 목록 표시

### **Scenario 3: 필터 토글 테스트**

1. **"Available Only"** 모드: 사용 가능한 효소만 표시
2. **"All Enzymes"** 모드: 모든 효소 표시 (사용 불가능한 것도 포함)

### **Scenario 4: 검색 기능 테스트**

1. 검색창에 **"Eco"** 입력
2. EcoRI, EcoRV 등 Eco로 시작하는 효소만 필터링
3. 염기서열 **"GAATTC"** 검색 시 EcoRI 매칭

---

## 📊 개선 전후 비교

### **개선 전**
- ❌ 모든 효소를 표시 (매칭 여부 관계없이)
- ❌ 사용자가 직접 어떤 효소가 사용 가능한지 확인 필요
- ❌ 효소별 매칭 사이트 개수 미표시
- ❌ 염기서열 정보 부족

### **개선 후**
- ✅ 현재 염기서열과 매칭되는 효소만 우선 표시
- ✅ 자동으로 염기서열 분석 수행
- ✅ 각 효소별 정확한 매칭 사이트 개수 표시
- ✅ 사용 가능/불가능 효소 시각적 구분
- ✅ 염기서열 미리보기 및 상세 정보 표시
- ✅ 필터링 및 검색 기능 강화

---

## 🎯 사용자 워크플로우

### **1단계: Gene 선택**
```
Gene Library → Gene 선택 (예: BRCA1) → Apply
```

### **2단계: Restriction Enzyme 분석**
```
Bottom Menu → Scissor 버튼 클릭
↓
자동 분석 시작 ("Analyzing...")
↓
사용 가능한 효소 목록 표시
```

### **3단계: 효소 선택 및 작업**
```
효소 목록에서 원하는 효소 선택
↓
Analyze 버튼: 상세 분석
Digest 버튼: 절단 시뮬레이션
Show 3D 버튼: 3D 구조에서 절단 위치 표시
```

---

## 🔍 주요 기능 상세

### **1. 자동 염기서열 분석**

```swift
.onAppear {
    analyzeSequenceForAvailableEnzymes()
}
```

- 앱 시작 시 자동으로 실행
- 백그라운드에서 비동기 처리
- 분석 중 로딩 인디케이터 표시

### **2. 실시간 필터링**

```swift
private var filteredEnzymes: [RestrictionEnzyme] {
    let enzymesToFilter = showOnlyAvailable ? availableEnzymes : RestrictionEnzyme.all
    
    if searchText.isEmpty {
        return enzymesToFilter
    } else {
        return enzymesToFilter.filter { enzyme in
            enzyme.name.localizedCaseInsensitiveContains(searchText) ||
            enzyme.sequence.localizedCaseInsensitiveContains(searchText)
        }
    }
}
```

### **3. 시각적 상태 표시**

- ✅ **사용 가능한 효소**: 밝게 표시, 사이트 개수 표시
- ❌ **사용 불가능한 효소**: 흐리게 표시, "No match" 표시
- 🔍 **분석 중**: 로딩 스피너 표시

### **4. 상세 정보 표시**

- 효소 이름 및 인식 서열
- 절단 위치 및 오버행 타입
- 매칭 사이트 개수
- 염기서열 미리보기

---

## 🚀 성능 최적화

### **비동기 처리**
```swift
Task {
    let analyzer = RestrictionSiteAnalyzer()
    let hitsDict = analyzer.analyze(sequence: sequence.sequence, enzymes: allEnzymes)
    
    await MainActor.run {
        // UI 업데이트
    }
}
```

### **메모리 효율성**
- 효소 데이터 lazy loading
- 분석 결과 캐싱
- 불필요한 재계산 방지

---

## 🧬 지원하는 Restriction Enzymes

### **주요 효소 (15개)**

| 효소명 | 인식서열 | 절단위치 | 오버행 |
|--------|----------|----------|--------|
| EcoRI | GAATTC | 1 | 5' overhang |
| BamHI | GGATCC | 1 | 5' overhang |
| HindIII | AAGCTT | 1 | 5' overhang |
| PstI | CTGCAG | 5 | 3' overhang |
| SacI | GAGCTC | 5 | 3' overhang |
| NotI | GCGGCCGC | 2 | 5' overhang |
| XbaI | TCTAGA | 1 | 5' overhang |
| SalI | GTCGAC | 1 | 5' overhang |
| XhoI | CTCGAG | 1 | 5' overhang |
| KpnI | GGTACC | 5 | 3' overhang |
| SmaI | CCCGGG | 3 | blunt |
| EcoRV | GATATC | 3 | blunt |
| DraI | TTTAAA | 3 | blunt |
| ScaI | AGTACT | 3 | blunt |
| PvuII | CAGCTG | 3 | blunt |

### **IUPAC 코드 지원**
- R: A 또는 G
- Y: C 또는 T
- S: G 또는 C
- W: A 또는 T
- K: G 또는 T
- M: A 또는 C
- N: A, C, G, T (모든 염기)

---

## 📝 테스트 체크리스트

### **기본 기능**
- [ ] Scissor 버튼 클릭 시 restriction enzyme 화면 표시
- [ ] 자동 염기서열 분석 수행
- [ ] 사용 가능한 효소만 기본 표시
- [ ] 각 효소별 매칭 사이트 개수 표시
- [ ] 필터 토글 버튼 작동

### **검색 및 필터링**
- [ ] 효소 이름으로 검색 가능
- [ ] 인식서열로 검색 가능
- [ ] "Available Only" / "All Enzymes" 전환
- [ ] 검색 결과 실시간 업데이트

### **UI/UX**
- [ ] 사용 가능한 효소 시각적 구분
- [ ] 분석 중 로딩 인디케이터 표시
- [ ] 염기서열 미리보기 표시
- [ ] 효소 상태 아이콘 표시

### **다양한 염기서열 테스트**
- [ ] BRCA1 (7,088 bp) - 다양한 효소 매칭
- [ ] TP53 (2,512 bp) - 다른 효소 패턴
- [ ] CFTR (6,070 bp) - 긴 염기서열
- [ ] APOE (1,166 bp) - 짧은 염기서열
- [ ] HBB (626 bp) - 매우 짧은 염기서열

### **성능 테스트**
- [ ] 큰 염기서열 (7,000+ bp) 분석 시간 < 2초
- [ ] 메모리 사용량 적정 수준
- [ ] UI 반응성 유지

---

## 🔧 추가 개선 가능 사항

### **1. 효소 데이터베이스 확장**
- 더 많은 restriction enzyme 추가
- 상용 효소 정보 포함
- 효소별 상세 정보 (온도, pH 등)

### **2. 고급 분석 기능**
- 다중 효소 동시 절단
- 절단 효율 계산
- 절단 조건 시뮬레이션

### **3. 교육 기능 강화**
- 효소별 상세 설명
- 절단 메커니즘 애니메이션
- 실험 가이드 제공

---

## 📚 참고 자료

### **Restriction Enzymes 정보**
- **NEB (New England Biolabs)**: https://www.neb.com/
- **Thermo Fisher Scientific**: https://www.thermofisher.com/
- **Promega**: https://www.promega.com/

### **IUPAC 코드**
- **NCBI IUPAC**: https://www.ncbi.nlm.nih.gov/books/NBK21134/

### **분자생물학 실험**
- **Restriction Digest Protocol**: 표준 절단 실험 방법
- **Gel Electrophoresis**: 절단 결과 확인 방법

---

**작성일**: 2025-10-19  
**버전**: v1.0  
**테스트 환경**: iOS 16.0+, Xcode 15.0+


