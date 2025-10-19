# Gene Apply 테스트 가이드

## 📋 개요

Gene Library에서 gene을 선택하고 "Apply" 버튼을 클릭하면 메인화면으로 이동하여 **그룹별 염기서열이 새로 업데이트**됩니다.

---

## 🔧 수정 사항

### **Step 1: LibraryView.fetchGeneSequence 함수 수정**

**문제점**: 
- ❌ 기존: `db=gene`로 직접 염기서열을 가져오려 함 (불가능)

**해결책**:
- ✅ 2단계 API 호출로 변경:
  1. **elink API**: Gene ID → Nucleotide Accession 변환
  2. **efetch API**: Nucleotide Accession → FASTA 염기서열 가져오기

**변경 내용**:
```swift
// 기존 (❌)
let urlString = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=gene&id=\(geneId)&rettype=fasta&retmode=text"

// 수정 후 (✅)
// Step 1: Gene ID → Nucleotide Accession
let accessions = try await NCBIService.shared.resolveAccessionsFromGeneUID(String(geneId), retmax: 1)

// Step 2: Accession → Sequence
let urlString = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=\(firstAccession)&rettype=fasta&retmode=text"
```

---

### **Step 2: ContentView에 .id() modifier 추가**

**목적**: `viewModel.currentSequence`가 변경되면 ViewerView를 완전히 재생성

**변경 내용**:
```swift
ViewerView(sequence: sequence, viewModel: viewModel)
    .id(sequence.id) // sequence가 변경되면 ViewerView를 재생성
```

---

### **Step 3: ViewerView 중복 코드 제거 및 로그 추가**

**변경 사항**:
- 중복된 `.onAppear` 제거
- 디버깅 로그 추가

**변경 내용**:
```swift
.onAppear {
    print("🎬 ViewerView.onAppear: \(sequence.name)")
    sceneManager.loadSequence(sequence)
}
.onChange(of: sequence.id) { newId in
    print("🔄 ViewerView.onChange(sequence.id): \(sequence.name) (id: \(newId))")
    sceneManager.loadSequence(sequence)
}
```

---

### **Step 4: applyGeneToMainView 함수 로그 개선**

**추가된 로그**:
- Gene 정보 (Symbol, ID, Chromosome)
- DNASequence 생성 정보 (Name, ID, Length)
- 예상 그룹 수 계산
- ViewModel 업데이트 확인

---

## 🧪 테스트 절차

### **1. 앱 실행**

```bash
# Xcode에서 실행
# 또는 시뮬레이터에서 빌드 & 실행
```

### **2. Gene Library 열기**

1. 메인 화면에서 **Library** 버튼 클릭
2. 카테고리 선택 (예: **Organism**)
3. Sub-category 선택 (예: **Homo sapiens**)

### **3. Gene 선택 및 Apply**

1. Gene 목록에서 원하는 gene 선택 (예: **BRCA1**)
2. **Apply** 버튼 클릭

### **4. 예상 동작 확인**

#### **콘솔 로그 순서**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 Applying gene to main view
   Gene Symbol: BRCA1
   Gene ID: 672
   Chromosome: 17
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 fetchGeneSequence: Gene ID = 672

✅ Found accession: 1732746264

📡 Fetching sequence from: https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=1732746264&rettype=fasta&retmode=text

✅ Sequence length: 7088 bp

📦 Created DNASequence:
   Name: BRCA1
   ID: [UUID]
   Length: 7088 bp
   Expected Groups: 71

🔄 Setting viewModel.currentSequence...

✅ Gene applied successfully!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎬 ViewerView.onAppear: BRCA1

🔄 loadSequence called: BRCA1

🔍 Calculating groups for sequence: 'BRCA1' (lowercased: 'brca1')
🔍 Sequence length: 7088

✅ Setting groupSize to 100 for consistent display

📊 Multiple groups (71): displayStart=0, displayLength=100

🧬 BRCA1: 7088 bases -> 71 groups (size: 100)
🧬 Final values: currentGroup=1, displayStart=0, displayLength=100

✅ loadSequence completed: totalGroups=71, currentGroup=1, displayStart=0, displayLength=100
```

#### **UI 확인 사항**:

1. ✅ Library sheet가 자동으로 닫힘
2. ✅ 메인 화면으로 이동
3. ✅ 상단에 gene 이름 표시 (예: "BRCA1")
4. ✅ 3D 구조가 새로운 염기서열로 렌더링
5. ✅ 하단 Sequence Bar에 그룹 버튼 표시
   - **BRCA1**: G1, G2, G3, ..., G71 (71개 그룹)
   - **TP53**: G1, G2, G3, ..., G26 (26개 그룹)
6. ✅ 첫 번째 그룹(G1)이 선택된 상태 (파란색)
7. ✅ G1 그룹의 염기서열 표시 (0-99 bp)

---

## 🧬 테스트할 Gene 목록

| Gene Symbol | Gene ID | Expected Length | Expected Groups |
|-------------|---------|-----------------|-----------------|
| BRCA1       | 672     | 7,088 bp        | 71 groups       |
| TP53        | 7157    | 2,512 bp        | 26 groups       |
| CFTR        | 1080    | 6,070 bp        | 61 groups       |
| APOE        | 348     | 1,166 bp        | 12 groups       |
| HBB         | 3043    | 626 bp          | 7 groups        |

---

## 🔍 테스트 시나리오

### **Scenario 1: 정상적인 Gene 선택**

1. Gene Library에서 **BRCA1** 선택
2. Apply 버튼 클릭
3. **예상 결과**:
   - 메인 화면으로 이동
   - 71개 그룹 표시 (G1~G71)
   - G1 선택된 상태 (파란색)
   - 첫 100bp 표시

### **Scenario 2: 다른 Gene으로 전환**

1. 메인 화면에서 Library 버튼 클릭
2. **TP53** 선택 및 Apply
3. **예상 결과**:
   - 이전 BRCA1 데이터가 완전히 대체됨
   - 26개 그룹 표시 (G1~G26)
   - 새로운 3D 구조 렌더링

### **Scenario 3: 그룹 전환**

1. Gene Apply 후 메인 화면
2. G1 버튼 클릭 → 0-99 bp 표시
3. G2 버튼 클릭 → 100-199 bp 표시
4. G3 버튼 클릭 → 200-299 bp 표시

### **Scenario 4: API 실패 처리**

네트워크가 없거나 API 에러 발생 시:
- 콘솔에 에러 로그 출력
- 샘플 시퀀스 (1000bp) 사용
- 10개 그룹 표시

---

## 🐛 디버깅 가이드

### **문제 1: 그룹이 업데이트되지 않음**

**증상**: Gene을 Apply했는데 이전 그룹이 그대로 표시

**원인 가능성**:
1. ContentView의 `.id()` modifier 미적용
2. ViewerView의 `.onChange(of: sequence.id)` 누락
3. DNASceneManager의 `loadSequence` 미호출

**확인 방법**:
```
콘솔에서 다음 로그 확인:
- 🔄 ViewerView.onChange(sequence.id): [Gene Name]
- 🔄 loadSequence called: [Gene Name]
- ✅ loadSequence completed: totalGroups=[N]
```

---

### **문제 2: API 호출 실패**

**증상**: "No sequence found" 에러

**원인 가능성**:
1. Gene ID에 nucleotide accession이 없음
2. 네트워크 연결 문제
3. NCBI API rate limiting (3 req/sec)

**확인 방법**:
```bash
# 수동으로 API 테스트
curl "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=gene&db=nuccore&id=672&retmode=json"
```

---

### **문제 3: 3D 구조가 렌더링되지 않음**

**증상**: 그룹은 표시되지만 3D 화면이 빈 상태

**원인 가능성**:
1. DNASceneManager의 `rebuildScene()` 실패
2. 염기서열에 유효하지 않은 문자 포함
3. SceneKit 렌더링 에러

**확인 방법**:
```
콘솔에서 다음 로그 확인:
- 🔍 Calculating groups for sequence
- ✅ Setting groupSize to 100
- 📊 Multiple groups ([N]): displayStart=0
```

---

## 📊 성공 기준

### ✅ 모든 항목이 체크되어야 합니다:

- [ ] Gene Apply 시 Library sheet가 닫힘
- [ ] 메인 화면으로 자동 전환
- [ ] 새로운 gene 이름이 상단에 표시
- [ ] 그룹 수가 염기서열 길이에 맞게 표시
  - 예: 7,088bp → 71 groups
- [ ] G1 그룹이 기본 선택된 상태 (파란색)
- [ ] 첫 100bp의 염기서열이 표시
- [ ] 3D 구조가 새로운 염기서열로 렌더링
- [ ] 다른 그룹 클릭 시 해당 구간 표시
- [ ] 연속으로 여러 gene을 Apply해도 정상 작동

---

## 🎯 추가 검증 사항

### **1. 메모리 관리**

여러 gene을 연속으로 Apply해도 메모리 누수 없이 정상 작동

```
Xcode Instruments로 확인:
- Allocations
- Leaks
```

### **2. 성능**

큰 염기서열(7000bp+)도 부드럽게 렌더링

```
- 그룹 전환 시 지연 없음
- 3D 구조 렌더링 1-2초 이내
```

### **3. 안정성**

네트워크 에러 시 graceful fallback

```
- Sample sequence 사용
- 사용자에게 명확한 에러 메시지
```

---

## 🚀 빠른 테스트 스크립트

```bash
# 1. 빌드 및 실행
cd /Users/richard/source/DNAViewer
xcodebuild -project DNAViewer.xcodeproj -scheme DNAViewer -destination 'platform=iOS Simulator,name=iPhone 15 Pro' clean build

# 2. 시뮬레이터에서 실행
open -a Simulator
xcrun simctl install booted [App Bundle Path]
xcrun simctl launch booted [Bundle Identifier]

# 3. 콘솔 로그 모니터링
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "DNAViewer"'
```

---

## 📝 체크리스트

### **코드 수정 완료**
- [x] LibraryView.fetchGeneSequence 함수 수정
- [x] NCBIService.resolveAccessionsFromGeneUID 활용
- [x] ContentView에 .id() modifier 추가
- [x] ViewerView 중복 코드 제거
- [x] 디버깅 로그 추가

### **테스트 완료**
- [ ] BRCA1 (7088bp → 71 groups)
- [ ] TP53 (2512bp → 26 groups)
- [ ] CFTR (6070bp → 61 groups)
- [ ] APOE (1166bp → 12 groups)
- [ ] HBB (626bp → 7 groups)

### **UI/UX 검증**
- [ ] Library sheet 자동 닫힘
- [ ] 메인 화면 전환 확인
- [ ] 그룹 버튼 표시 확인
- [ ] 3D 구조 렌더링 확인
- [ ] 염기서열 표시 확인

---

**작성일**: 2025-10-19  
**버전**: v1.0  
**테스트 환경**: iOS 16.0+, Xcode 15.0+

