# Ladder & Genome Map Implementation Plan

## 1. 데이터 모델 확장
- [ ] `DNASequence` 혹은 관련 ViewModel에 `BasePair`, `GeneMark` 컬렉션을 노출할 계산 속성/캐시 추가
- [ ] 유전자/마커 메타데이터를 가져오는 데이터 소스(예: JSON, API, CoreData) 정의
- [ ] `GeneMark` 색상 팔레트와 타입(enum) 설계 (예: 기본 유전자, 변이, CpG 등)

## 2. Ladder 뷰 (2D 사다리)
1. **뷰 생성**
   - [ ] `DNALadderView` SwiftUI 뷰를 `Sources/Views/Ladder` 폴더에 추가
   - [ ] `Canvas` 기반 렌더링 코드 구현 (백본·가로 막대·문자)
2. **상호작용**
   - [ ] 스크롤 & 핀치 확대를 위해 `ScrollView` + `MagnificationGesture` 통합
   - [ ] 선택/탭 제스처로 특정 base pair 하이라이트 기능 고려
3. **테마/Legend**
   - [ ] 색상 레전드 컴포넌트 (`LegendView`) 작성 및 UI 배치
   - [ ] 다크모드 대비 색상 대비 검토

## 3. Genome Map 뷰 (선형 지도)
1. **레이아웃**
   - [ ] `GenomeMapView` SwiftUI 뷰 추가
   - [ ] `GeometryReader` 기반으로 전체 길이 대비 위치 비율 계산
   - [ ] 스크롤 영역 및 Zoom 컨트롤 구성
2. **마커 렌더링**
   - [ ] `GeneMark` 리스트를 통해 `RoundedRectangle` + 텍스트 배치
   - [ ] 마커 최소 길이 보정 및 오버랩 처리 로직 추가 (예: offset stack, small bump)
3. **툴팁/Popover**
   - [ ] 마커 탭 시 좌표, 설명, 기능 링크를 포함한 팝오버/시트 표시
   - [ ] iOS/macOS 별 적절한 프레젠테이션 방식(if #available)

## 4. 뷰 통합
- [ ] 기존 `DNAViewer` UI에 스타일 전환 토글 추가 (`Ladder`, `Map`, `Double Helix`, ...)
- [ ] ViewModel에 선택된 스타일 상태(`@Published var representation`)와 필요한 데이터 공급
- [ ] `DNASceneManager`와 2D 뷰 간 전환 시 애니메이션/상태 유지 검토

## 5. 데이터 준비 & 시나리오
- [ ] 샘플 시퀀스/유전자 데이터 세트 작성 (Chromosome 17, BRCA1/TP53 등)
- [ ] 긴 염기서열 테스트 (성능/메모리 확인)
- [ ] 없는 데이터(예: start/end 미정) 처리 규칙 정의

## 6. 기능 확장 로드맵
- [ ] **툴팁 강화**: GeneMark 구조에 설명/ClinVar 링크 추가, popover에서 상세 정보 표시
- [ ] **멀티 트랙**: 변이, CpG, 제한효소 사이트를 개별 트랙으로 렌더 (Stacked layout)
- [ ] **Swift Charts 연동**: GC content, coverage 라인 차트 및 히트맵 오버레이
- [ ] **공유/Export**: Ladder/Map 뷰를 이미지로 캡처해 저장/공유 기능 구현

## 7. 테스트 & 검증
- [ ] SwiftUI Snapshot 테스트 또는 스크린샷 비교
- [ ] 유닛 테스트: BasePair 상보성, GeneMark 정렬/비율 계산 검증
- [ ] 접근성 체크: Dynamic Type, VoiceOver 라벨링

## 8. 문서화
- [ ] README 섹션 업데이트: 새 스타일 소개, 스크린샷
- [ ] 코드 주석 및 아키텍처 설명 추가
- [ ] 차후 기여자용 개발 가이드 작성

---

### 작업 순서 제안 (Milestones)

1. **MVP**: `DNALadderView` + `GenomeMapView` 기본 렌더링, 샘플 데이터 연결
2. **Interaction**: 줌/팬, 마커 선택, 뷰 전환 UI
3. **Enhancement**: 툴팁, 멀티 트랙, Charts 통합
4. **Polish**: 접근성, 성능 튜닝, 문서화 & 테스트