# DNA Viewer v1.0.2 - App Store Update Notes

## Version Information
- **Version**: 1.0.2
- **Build**: 7
- **Release Date**: October 24, 2025

---

## What's New in Version 1.0.2

### 🎨 New Visualization Styles
- **Genome Map Style**: New visualization mode showing gene structure, chromosome ideogram, and genomic location
- **Enhanced Control Bar**: Added close button for better user control and improved UI/UX

### 🐛 Bug Fixes and Improvements
- Fixed gene information display to show correct data for all genes (not just BRCA1)
- Fixed chromosome visualization to show accurate chromosome numbers and positions
- Fixed species labels to display correct genome type (Human, Mouse, etc.) for all organisms
- Improved gene symbol recognition for better compatibility with genomic databases
- Enhanced position tracking in gene structure visualization
- Fixed sequence data synchronization between different views
- Better error handling and user feedback

---

## 한국어 (Korean)

### v1.0.2 새로운 기능

### 🎨 새로운 시각화 스타일
- **Genome Map 스타일**: 유전자 구조, 염색체 ideogram, 게놈 위치를 보여주는 새로운 시각화 모드
- **향상된 Control Bar**: 닫기 버튼 추가로 더 나은 사용자 제어 및 UI/UX 개선

### 🐛 버그 수정 및 개선사항
- 모든 유전자에 대해 올바른 정보를 표시하도록 수정 (BRCA1뿐만 아니라)
- 정확한 염색체 번호와 위치를 표시하도록 염색체 시각화 수정
- 모든 생물에 대해 올바른 게놈 유형(인간, 마우스 등) 표시하도록 수정
- 게놈 데이터베이스와의 호환성을 위한 유전자 심볼 인식 개선
- 유전자 구조 시각화의 위치 추적 향상
- 다른 뷰 간 염기서열 데이터 동기화 수정
- 더 나은 오류 처리 및 사용자 피드백

---

## 상세 기능 설명

### 🌍 다중 생물종 지원
- **270+ 생물종 지원**: Ensembl 데이터베이스의 모든 생물종 지원
- 선택한 생물의 정확한 게놈 정보 자동 표시
- 인간, 마우스, 쥐, 초파리, 제브라피쉬 등 지원
- 생물종 이름 자동 포맷팅 (예: "Homo Sapiens Genome", "Mus Musculus Genome")

### 🧬 동적 유전자 정보 표시
- **모든 유전자 지원**: BRCA1뿐만 아니라 모든 유전자 정보 확인 가능
- Ensembl 및 NCBI 데이터베이스에서 실시간 데이터 제공
- 정확한 유전자 설명, 염색체 위치, 전사체 정보
- 실제 게놈 위치 기반 인접 유전자 표시

### 📊 정확한 염색체 시각화
- **실제 염색체 데이터 사용**: 24개 인간 염색체의 GRCh38/hg38 assembly 데이터 사용
- 각 염색체의 정확한 centromere 위치
- 실제 게놈 좌표 기반 유전자 마커 위치
- 과학적 정확성을 위한 메가베이스(Mb) 단위 위치 표시

### 🎯 개선된 유전자 구조 시각화
- **정확한 위치 추적**: 유전자 구조 다이어그램에 현재 그룹 위치 정확하게 표시
- 그룹 번호와 퍼센트를 보여주는 향상된 위치 표시기
- Sequence Bar와 정확히 일치하는 염기서열 표시
- 깜빡이는 위치 마커로 더 나은 시각적 피드백

### 🔍 향상된 유전자 심볼 인식
- **스마트 심볼 추출**: 적절한 유전자 심볼(CRB1, IL2 등)을 인식하는 개선된 알고리즘
- 다양한 데이터베이스의 명명 형식 지원
- 생물종별 명명법 더 잘 처리
- 잘못된 심볼 파싱으로 인한 API 오류 감소

---

## For Scientists and Researchers
This update makes DNA Viewer a true multi-species genomic visualization tool:

✅ **Universal Gene Support**: View any gene from any supported organism  
✅ **Accurate Genomic Data**: Real chromosome lengths, centromere positions, and gene coordinates  
✅ **Cross-Species Research**: Seamlessly switch between human, model organisms, and other species  
✅ **Data Integrity**: Direct integration with Ensembl and NCBI databases  
✅ **Educational Tool**: Perfect for teaching genomics across multiple organisms  

---

## App Store Description

**English:**
- New Genome Map visualization and Ladder 2D style
- Bug fixes for gene information, chromosome display, and species support

**한국어 (Korean):**
- 새로운 Genome Map 시각화 및 Ladder 2D 스타일
- 유전자 정보, 염색체 표시 및 생물종 지원 버그 수정

**日本語 (Japanese):**
- 新しいGenome Map可視化とLadder 2Dスタイル
- 遺伝子情報、染色体表示、種サポートのバグ修正

**Deutsch (German):**
- Neue Genome Map-Visualisierung und Ladder 2D-Stil
- Fehlerbehebungen für Geninformationen, Chromosomendarstellung und Artenunterstützung

---

## Technical Notes (for App Review)

### API Integrations:
1. **Ensembl REST API** (https://rest.ensembl.org)
   - Gene lookup and genomic data
   - Chromosome information
   - Transcript and exon data

2. **NCBI E-utilities API** (https://eutils.ncbi.nlm.nih.gov)
   - Gene sequence data
   - Gene library and search

### Network Usage:
- Required for fetching real-time genomic data
- All API calls use HTTPS
- Proper error handling with fallback data
- Rate limiting implemented (0.5s between requests)

### Privacy:
- No user data collected
- No analytics or tracking
- All API calls are for scientific data only

---

## Testing Checklist

- [x] Build succeeds without errors
- [x] All hardcoded values removed
- [x] Multi-species support verified (Human, Mouse, Drosophila)
- [x] Gene symbol extraction works for various formats
- [x] Position indicators accurate
- [x] Sequence display matches between views
- [x] API error handling works properly
- [x] Version and build numbers updated

---

## Release Notes Summary

**What Users Will Notice:**
1. Can now view genes from any organism (not just human)
2. Accurate species-specific genome information
3. Correct chromosome labels and positions
4. Better position tracking in gene structure view
5. More reliable gene symbol recognition

**For Developers:**
- Removed all hardcoded BRCA1/Chr17/Human genome references
- Implemented dynamic data fetching from APIs
- Added comprehensive species support
- Improved error handling and logging
- Better code maintainability

---

## Screenshots to Update

Recommended screenshots to showcase new features:
1. Human gene (BRCA1) on Chr17 - Human Genome
2. Mouse gene (Il2) on Chr3 - Mouse Genome  
3. Drosophila gene (Fas2) on ChrX - Drosophila Melanogaster Genome
4. Gene structure view showing accurate position tracking
5. Gene information panel with dynamic data

---

## Submission Metadata

**Category**: Education  
**Age Rating**: 4+  
**Keywords**: DNA, genome, genetics, visualization, science, education, research, biology, chromosomes, genes  
**Support URL**: https://github.com/Richard-JHLee/DNAViewer  

**Copyright**: © 2025 Richard Lee. All rights reserved.

