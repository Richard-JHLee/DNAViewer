# DNAViewer 사이드바 메뉴 항목 제안

## 📋 ProteinApp 메뉴 구조 분석

### **ProteinApp 메뉴 항목** (8개):
1. **About** - 앱 정보 및 버전
2. **User Guide** - 사용자 가이드
3. **Features** - 주요 기능
4. **Settings** - 앱 설정
5. **Help** - 도움말 및 FAQ
6. **Privacy Policy** - 개인정보 처리방침
7. **Terms of Service** - 이용약관
8. **License** - 라이선스 정보

---

## 🎯 DNAViewer 메뉴 항목 제안 (Settings 제외)

### **현재 DNAViewer 메뉴** (5개):
1. ✅ Sample Genes Library
2. ✅ Analysis Tools
3. ✅ Restriction Enzymes
4. ❌ Settings (제외 요청)
5. ✅ About

---

## 🆕 제안하는 DNAViewer 메뉴 구조

### **Option 1: 기본 구성** (6개 항목)

```
📚 Gene Library
   └─ Browse and explore genetic sequences

📊 Analysis Tools  
   └─ GC Content, CpG Islands, Sequence Analysis

✂️ Restriction Enzymes
   └─ Cut DNA & Educational Features

📖 User Guide
   └─ How to use DNA Viewer

❓ Help & FAQ
   └─ Common questions and troubleshooting

ℹ️ About
   └─ App information and version
```

**장점**:
- ✅ 깔끔하고 간결
- ✅ 핵심 기능 중심
- ✅ 사용자 친화적

---

### **Option 2: 확장 구성** (8개 항목)

```
📚 Gene Library
   └─ Browse NCBI gene database

📊 Analysis Tools  
   └─ Sequence analysis and statistics

✂️ Restriction Enzymes
   └─ Virtual DNA digestion tools

⭐ Features
   └─ Key features and capabilities

📖 User Guide
   └─ Step-by-step tutorials

❓ Help & FAQ
   └─ Common questions and answers

🔬 Educational Resources
   └─ Learn about genetics and DNA

ℹ️ About
   └─ App info, version, and credits
```

**장점**:
- ✅ 더 많은 정보 제공
- ✅ 교육 섹션 추가
- ✅ 전문적인 구성

---

### **Option 3: ProteinApp 스타일 완전 적용** (9개 항목)

```
📚 Gene Library
   └─ Browse and explore genetic sequences

📊 Analysis Tools  
   └─ Sequence analysis features

✂️ Restriction Enzymes
   └─ Virtual DNA cutting tools

⭐ Features
   └─ Key features overview

📖 User Guide
   └─ How to use the app

❓ Help
   └─ Help and FAQ

🔒 Privacy Policy
   └─ Data privacy information

📄 Terms of Service
   └─ Terms and conditions

ℹ️ About
   └─ App information and license
```

**장점**:
- ✅ ProteinApp과 완전히 동일한 구조
- ✅ 법적 정보 포함 (Privacy, Terms)
- ✅ 기업용 앱에 적합

---

## 💡 추천: **Option 1 (기본 구성)** + **선택적 추가**

### **필수 항목** (6개):

```swift
enum DNAMenuItemType: String, CaseIterable {
    case geneLibrary = "Gene Library"
    case analysisTools = "Analysis Tools"
    case restrictionEnzymes = "Restriction Enzymes"
    case userGuide = "User Guide"
    case help = "Help & FAQ"
    case about = "About"
    
    var icon: String {
        switch self {
        case .geneLibrary: return "books.vertical.fill"
        case .analysisTools: return "chart.bar.fill"
        case .restrictionEnzymes: return "scissors.badge.ellipsis"
        case .userGuide: return "book.fill"
        case .help: return "questionmark.circle.fill"
        case .about: return "info.circle.fill"
        }
    }
    
    var subtitle: String {
        switch self {
        case .geneLibrary: return "Browse NCBI gene database"
        case .analysisTools: return "GC Content, CpG Islands, Analysis"
        case .restrictionEnzymes: return "Cut DNA & Educational Features"
        case .userGuide: return "Learn how to use DNA Viewer"
        case .help: return "Common questions and troubleshooting"
        case .about: return "Version 1.0.0 • App information"
        }
    }
    
    var color: Color {
        switch self {
        case .geneLibrary: return .purple
        case .analysisTools: return .blue
        case .restrictionEnzymes: return .orange
        case .userGuide: return .green
        case .help: return .teal
        case .about: return .indigo
        }
    }
}
```

### **선택적 추가 항목** (필요 시):

```swift
case features = "Features"
// └─ icon: "star.fill"
// └─ subtitle: "Key features and capabilities"
// └─ color: .yellow

case educationalResources = "Educational Resources"
// └─ icon: "graduationcap.fill"
// └─ subtitle: "Learn about genetics and DNA"
// └─ color: .pink

case privacyPolicy = "Privacy Policy"
// └─ icon: "hand.raised.fill"
// └─ subtitle: "Data privacy information"
// └─ color: .gray

case termsOfService = "Terms of Service"
// └─ icon: "doc.text.fill"
// └─ subtitle: "Terms and conditions"
// └─ color: .brown
```

---

## 🎨 메뉴 레이아웃 제안

### **시각적 구성**:

```
┌──────────────────────────────────────┐
│ ┌──┐ DNA Viewer              ✕     │
│ │🧬│ Genetic Explorer              │
├──────────────────────────────────────┤
│                                      │
│ 📚 Gene Library                      │
│    Browse NCBI gene database    >    │
│                                      │
│ 📊 Analysis Tools                    │
│    GC Content, CpG Islands...   >    │
│                                      │
│ ✂️ Restriction Enzymes               │
│    Cut DNA & Educational...     >    │
│                                      │
│ 📖 User Guide                        │
│    Learn how to use...          >    │
│                                      │
│ ❓ Help & FAQ                        │
│    Common questions...          >    │
│                                      │
│ ℹ️ About                             │
│    Version 1.0.0 • App info     >    │
│                                      │
├──────────────────────────────────────┤
│           © 2025 AVAS                │
│       All rights reserved            │
└──────────────────────────────────────┘
```

---

## 📊 항목별 상세 설명

### **1. Gene Library** (필수)
- **아이콘**: 📚 books.vertical.fill
- **색상**: Purple
- **설명**: Browse NCBI gene database
- **기능**: 
  - NCBI API 연동 gene 검색
  - 카테고리별 탐색
  - Gene 정보 상세 보기

### **2. Analysis Tools** (필수)
- **아이콘**: 📊 chart.bar.fill
- **색상**: Blue
- **설명**: GC Content, CpG Islands, Analysis
- **기능**:
  - GC Content 분석
  - CpG Islands 탐지
  - 염기 조성 통계
  - 코돈 사용 빈도

### **3. Restriction Enzymes** (필수)
- **아이콘**: ✂️ scissors.badge.ellipsis
- **색상**: Orange
- **설명**: Cut DNA & Educational Features
- **기능**:
  - 제한효소 선택 및 분석
  - 가상 DNA 절단
  - Gel Electrophoresis
  - Cloning 시뮬레이션

### **4. User Guide** (추천)
- **아이콘**: 📖 book.fill
- **색상**: Green
- **설명**: Learn how to use DNA Viewer
- **내용**:
  - 기본 사용법
  - 주요 기능 튜토리얼
  - 팁과 트릭
  - 비디오 가이드 (선택)

### **5. Help & FAQ** (추천)
- **아이콘**: ❓ questionmark.circle.fill
- **색상**: Teal
- **설명**: Common questions and troubleshooting
- **내용**:
  - 자주 묻는 질문
  - 문제 해결 가이드
  - 연락처 정보
  - 피드백 제출

### **6. About** (필수)
- **아이콘**: ℹ️ info.circle.fill
- **색상**: Indigo
- **설명**: Version 1.0.0 • App information
- **내용**:
  - 앱 버전 정보
  - 개발자 정보
  - 크레딧 및 감사
  - 오픈소스 라이센스

---

## 🔧 구현 방법

### **Step 1: MenuItemType enum 생성**

`Sources/Models/DNAMenuItemType.swift` 파일 생성:

```swift
import SwiftUI

enum DNAMenuItemType: String, CaseIterable {
    case geneLibrary = "Gene Library"
    case analysisTools = "Analysis Tools"
    case restrictionEnzymes = "Restriction Enzymes"
    case userGuide = "User Guide"
    case help = "Help & FAQ"
    case about = "About"
    
    var icon: String {
        switch self {
        case .geneLibrary: return "books.vertical.fill"
        case .analysisTools: return "chart.bar.fill"
        case .restrictionEnzymes: return "scissors.badge.ellipsis"
        case .userGuide: return "book.fill"
        case .help: return "questionmark.circle.fill"
        case .about: return "info.circle.fill"
        }
    }
    
    var subtitle: String {
        switch self {
        case .geneLibrary: return "Browse NCBI gene database"
        case .analysisTools: return "GC Content, CpG Islands, Analysis"
        case .restrictionEnzymes: return "Cut DNA & Educational Features"
        case .userGuide: return "Learn how to use DNA Viewer"
        case .help: return "Common questions and troubleshooting"
        case .about: return "Version 1.0.0 • App information"
        }
    }
    
    var color: Color {
        switch self {
        case .geneLibrary: return .purple
        case .analysisTools: return .blue
        case .restrictionEnzymes: return .orange
        case .userGuide: return .green
        case .help: return .teal
        case .about: return .indigo
        }
    }
}
```

### **Step 2: SidebarMenu 업데이트**

기존 하드코딩된 MenuItem → enum 기반으로 변경:

```swift
// Menu Items
ScrollView {
    VStack(alignment: .leading, spacing: 0) {
        ForEach(DNAMenuItemType.allCases, id: \.self) { item in
            MenuItem(
                icon: item.icon,
                title: item.rawValue,
                subtitle: item.subtitle,
                color: item.color
            ) {
                isPresented = false
                handleMenuSelection(item)
            }
        }
    }
    .padding(.horizontal, 20)
}

private func handleMenuSelection(_ item: DNAMenuItemType) {
    switch item {
    case .geneLibrary: onLibrary()
    case .analysisTools: onAnalysis()
    case .restrictionEnzymes: onRestrictionEnzymes()
    case .userGuide: onUserGuide()
    case .help: onHelp()
    case .about: onAbout()
    }
}
```

### **Step 3: 새로운 View 생성**

필요한 View 파일들:

```
Sources/Views/
├── UserGuideView.swift
├── HelpView.swift
├── FeaturesView.swift (선택)
└── AboutView.swift (기존 확장)
```

---

## 📱 최종 추천 메뉴 구성

### **6개 항목 (Settings 제외)**:

```
1. 📚 Gene Library
   └─ Browse NCBI gene database

2. 📊 Analysis Tools
   └─ GC Content, CpG Islands, Analysis

3. ✂️ Restriction Enzymes
   └─ Cut DNA & Educational Features

4. 📖 User Guide
   └─ Learn how to use DNA Viewer

5. ❓ Help & FAQ
   └─ Common questions and troubleshooting

6. ℹ️ About
   └─ Version 1.0.0 • App information
```

---

## 🎨 디자인 예시

### **MenuItem 카드 형식**:

```
┌────────────────────────────────────┐
│ ┌──┐  Gene Library             > │
│ │📚│  Browse NCBI gene database   │
│ └──┘                               │
├────────────────────────────────────┤
│ ┌──┐  Analysis Tools           > │
│ │📊│  GC Content, CpG Islands...  │
│ └──┘                               │
├────────────────────────────────────┤
│ ┌──┐  Restriction Enzymes      > │
│ │✂️│  Cut DNA & Educational...    │
│ └──┘                               │
├────────────────────────────────────┤
│ ┌──┐  User Guide               > │
│ │📖│  Learn how to use...         │
│ └──┘                               │
├────────────────────────────────────┤
│ ┌──┐  Help & FAQ                > │
│ │❓│  Common questions...          │
│ └──┘                               │
├────────────────────────────────────┤
│ ┌──┐  About                     > │
│ │ℹ️│  Version 1.0.0 • App info    │
│ └──┘                               │
└────────────────────────────────────┘
```

---

## 🔄 선택적 추가 항목

### **더 추가하고 싶다면**:

#### **7. Features** (선택)
```
⭐ Features
   └─ Key features and capabilities
```
**내용**:
- 3D DNA 구조 시각화
- NCBI API 실시간 데이터
- Restriction enzyme 분석
- Virtual cloning
- Educational tools

#### **8. Educational Resources** (선택)
```
🎓 Educational Resources
   └─ Learn about genetics and DNA
```
**내용**:
- DNA 구조 설명
- 유전학 기초
- 분자생물학 개념
- 실험 프로토콜

#### **9. License** (선택)
```
📝 License
   └─ Open source licenses and credits
```
**내용**:
- MIT License
- 사용된 오픈소스 라이브러리
- NCBI 데이터 출처
- 크레딧

---

## ✅ 최종 추천

### **6개 항목 (Option 1)**이 가장 적합합니다:

**이유**:
1. ✅ 깔끔하고 간결
2. ✅ 핵심 기능에 집중
3. ✅ 사용자가 쉽게 이해
4. ✅ 불필요한 복잡성 없음
5. ✅ ProteinApp 형식 유지
6. ✅ Settings 제외 요구사항 충족

**추가 고려사항**:
- 나중에 Features, Educational Resources, License 등은 About 안에 포함 가능
- 처음에는 간단하게 시작하고 필요에 따라 확장
- Settings는 제거했지만 필요하면 Top Bar나 About 안에 포함 가능

---

**제안 적용 여부**를 알려주시면 바로 구현하겠습니다! 🚀

