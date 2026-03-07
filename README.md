## AlbaTime (알바타임)
AlbaTime은 아르바이트 근무 일정을 관리하고, 복잡한 급여 계산(주휴, 야간, 연장 수당 및 세금)을 자동으로 처리하여 예상 월급을 시각화해 주는 iOS 애플리케이션입니다.

## 주요 기능 (Key Features)

```text
1. 정교한 급여 계산 (Salary Calculation)
사용자가 설정한 근무지 정보를 바탕으로 예상 급여를 실시간으로 계산합니다. (SalaryCalculator.swift)
기본급 계산: 시급 × 근무 시간
주휴수당 적용: 주 15시간 이상 근무 시 주휴수당 자동 산정 (법정 기준 준수)
야간 수당: 22:00 ~ 06:00 사이 근무 시 1.5배 가산
연장 수당: 하루 8시간 초과 근무 시 1.5배 가산

세금 공제 시뮬레이션:
미적용
3.3% (사업소득세)
9.32% (4대보험 근로자 부담분)
```
```text
2. 근무지 및 일정 관리 (Workplace Management)
다중 근무지 지원: 여러 개의 아르바이트(예: 편의점, 카페)를 등록하고 개별 관리 가능
근무 패턴 설정: 요일별 고정 근무 시간, 시급, 휴게 시간 설정
SwiftData 기반 로컬 저장: 근무지(Workplace) 및 월별 기록(MonthlyRecord) 영구 저장
```
```text
4. 설계
MVVM 패턴 적용: PayViewModel을 통해 데이터 변화를 UI에 즉각 반영
급여 명세서: 기본급, 각종 수당, 공제 세금을 구분하여 상세 내역 제공
기술 스택 (Tech Stack)
Language: Swift
Framework: SwiftUI
Architecture: MVVM (Model-View-ViewModel)
Database: SwiftData (iOS 17+)
Tools: Xcode 16.0+
```
```text
5. AI OCR 엔진 탑재
VisionAI 기반 OCR 엔진을 탑재하여 자동으로 스케줄이 인식되도록 함
```
```text
6. 아키텍처 및 데이터 흐름 (Architecture & Data Flow)
이 프로젝트는 MVVM 패턴을 준수하며, SwiftData를 사용하여 데이터를 관리합니다.
폴더 구조 (Folder Structure)

AlbaTime
├── App
│   ├── AlbaTimeApp.swift              # 앱 진입점 및 SwiftData 컨테이너 설정
│   ├── MainTabView.swift              # 메인 탭 구조 (캘린더 / 근무지 / 급여 / 설정)
│   ├── SplashView.swift               # 앱 시작 스플래시 화면
│   ├── NotificationManager.swift      # 출근 알림 등록 및 갱신 관리
│   └── NextShiftSyncService.swift     # 다음 근무 데이터 위젯 동기화
├── AI Engine
│   ├── OCRService.swift               # Vision 기반 멀티패스 OCR 처리
│   ├── TextLayoutAnalyzer.swift       # OCR 텍스트 행/레이아웃 분석
│   ├── ScheduleParser.swift           # OCR 결과를 근무 스케줄로 파싱
│   └── ParsedSchedule.swift           # 파싱된 스케줄 모델
├── Model
│   ├── WorkPlace.swift                # 근무지 루트 모델 (SwiftData)
│   ├── WorkSchedule.swift             # 실제 / AI 저장 근무 스케줄 모델
│   ├── RegularSchedule.swift          # 고정 근무 요일별 스케줄 모델
│   ├── WorkTimePreset.swift           # OCR 스케줄 매핑용 시간 프리셋 모델
│   ├── MonthlyRecord.swift            # 월별 실제 수령액 기록 모델
│   └── AIListModels.swift             # AI 스케줄 관련 보조 모델
├── ViewModel
│   ├── PayViewModel.swift             # 급여 계산 및 대시보드 데이터 가공
│   ├── CalendarViewModel.swift        # 캘린더 월간 데이터 및 캐시 관리
│   ├── AddJobViewModel.swift          # 근무지 등록 / 수정 로직
│   ├── ScheduleImportViewModel.swift  # OCR 스케줄 분석 및 저장 로직
│   ├── ScheduleImportSelectionViewModel.swift # OCR 주차 선택 보조 상태 관리
│   ├── AISavedSchedulesPanelViewModel.swift   # 저장된 AI 스케줄 패널 상태 관리
│   └── RealAchiveRecordViewModel.swift        # 실제 수령액 기록 입력 / 관리
├── View
│   ├── Calendar/                      # 캘린더 관련 뷰
│   ├── Job/                           # 근무지 목록 / 추가 / 상세 / AI 스케줄 뷰
│   ├── Pay/                           # 급여 대시보드 및 급여 카드 뷰
│   ├── Settings/                      # 설정 / 도움말 / 앱 정보 뷰
│   └── ViewComponents/                # 공용 UI 컴포넌트
├── Extensions
│   ├── SalaryCalculator.swift         # 급여 계산 핵심 로직
│   ├── SalaryBreakdown.swift          # 급여 계산 결과 구조체
│   ├── Date.swift                     # 날짜 계산 / 포맷 헬퍼
│   └── Color+Theme.swift              # 앱 공통 테마 색상 확장
├── Resources
│   ├── Haptics.swift                  # 햅틱 피드백 유틸리티
│   ├── KeyboardUX.swift               # 입력 필드 키보드 이동 UX 지원
│   ├── PreviewHelper.swift            # SwiftUI 프리뷰 보조 코드
│   └── Assets.xcassets/               # 앱 아이콘 및 에셋 리소스
├── AlbaTimeWidget
│   ├── Widget/AlbaTimeWidgetBundle.swift      # 위젯 번들 진입점
│   ├── Widget/NextShiftWidget.swift           # 다음 근무 위젯 정의
│   ├── Widget/Provider/NextShiftTimelineProvider.swift # 위젯 타임라인 생성
│   ├── Widget/Repository/NextShiftWidgetRepository.swift # App Group 데이터 조회
│   ├── Widget/Model/WidgetModel.swift         # 위젯 표시용 데이터 모델
│   ├── Widget/Model/NextShiftWidgetEntry.swift # 위젯 엔트리 모델
│   ├── Widget/View/WidgetView.swift           # 위젯 UI
│   ├── Widget/ViewModel/WidgetViewModel.swift # 위젯 표시 상태 가공
│   └── Widget/Extensions/Color.swift          # 위젯 전용 색상 확장
└── AlbaTimeTests
    └── AlbaTimeTests.swift            # 테스트 코드

```

<img width="1300" height="1000" alt="SwiftData Workplace-2026-03-07-081530" src="https://github.com/user-attachments/assets/4b4b978f-8459-4bb1-b9ad-46a0af1061ac" />

<img width="500" height="1500" alt="image" src="https://github.com/user-attachments/assets/d18321de-243c-41d7-9cf3-8f3d023b6519" />



## 실제 구현 화면
<img width="250" alt="IMG_1588" src="https://github.com/user-attachments/assets/cf661780-95c6-4d0c-ad4e-b6193acb1e58" /> <img width="250" alt="Simulator Screenshot - iPhone 17 Pro - 2026-01-13 at 16 07 15" src="https://github.com/user-attachments/assets/bff06303-6946-47a5-88d5-375d6859fc32" /> <img width="250" alt="Simulator Screenshot - iPhone 17 Pro - 2026-01-13 at 16 07 25" src="https://github.com/user-attachments/assets/fa657240-ff38-4a8f-941f-ea152237369d" /> <img width="250" alt="Simulator Screenshot - iPhone 17 Pro - 2026-01-13 at 16 07 32" src="https://github.com/user-attachments/assets/425c44a6-79f0-47d3-be62-150bc3c53ff8" />



## V1.0.0 개발기간
2025.12.8 ~ 2025.1.13

## V1.1.0 개발기간
2025.1.13 ~ 2025.1.24

업데이트
1. visionAi 기반 ai ocr engine 탑재
2. 고정, 자율 스케줄 따로 저장가능하도록 업데이트

## V1.2.0 개발기간
2026.1.24 ~ 2026.2.18

업데이트
1. AI 스케줄 관리 개선
   1-1) 월/주차 기준으로 AI 스케줄 저장 및 불러오기 구조 정리
   1-2) 저장된 AI 스케줄을 주차 단위로 수정할 수 있는 편집 흐름 추가
   1-3) 근무지별로 AI 스케줄 데이터가 분리 관리되도록 개선
2. OCR 인식 안정화
   2-1) 단일 OCR인식에서 다중패스 인식 및 후처리 병합으로 변경하여 OCR 인식률 대폭 상승
3. 급여 계산 로직 개선
   3-1) 월 예상 금액 중심에서 실제 누적 금액 중심으로 계산 흐름 개선
   3-2) 근무 종료 시점 기준 누적 반영 로직 적용
   3-3) 휴게시간/수당 반영 분기 정리 및 계산 정확도 개선
4. 위젯 개발
   4-1) 다음 근무 정보 위젯 추가
   4-2) 앱 데이터와 위젯 간 동기화 로직 적용
   4-3) 위젯 표시 텍스트 및 시간 계산 로직 개선
5. 근무지/캘린더 동기화 개선
   5-1) AI로 저장한 스케줄이 캘린더에 주차 기준으로 반영되도록 개선
   5-2) 고정근무/자율근무 모두 동일한 동기화 흐름으로 정리
   5-3) 스케줄 수정 후 캘린더/알림 갱신 안정성 강화
6. UI/UX 개선
   6-1) AI 스케줄 화면의 주차 선택/편집 UI 개선
   6-2) 요일 선택 기반 단일 카드 편집 방식 도입
   6-3) 화면 이동 흐름 및 저장 후 복귀 동작 정리
7. 버그 수정
   7-1) AI 스케줄 저장/수정 시 반영 누락 문제 수정
   7-2) 자율근무에서 저장 실패하던 케이스 수정
   7-3) 위젯/근무시간 표시 관련 다수 예외 케이스 수정
   
## V1.2.1 개발기간
2026.2.18 ~ 2026.3.1

업데이트
1. 캘린더 탐색 UX 개선
   1-1) 월간 캘린더에서 좌우 스와이프로 월 이동이 가능하도록 개선
   1-2) 연도 / 월을 버튼형으로 구성해 원하는 시점으로 더 빠르게 이동할 수 있도록 개선

2. 급여 화면 인터랙션 개선
   2-1) 급여 카드 전환 애니메이션을 더 자연스럽게 수정
   2-2) 카드 전환 힌트 문구를 추가해 사용자가 기능을 더 쉽게 인지할 수 있도록 개선
   2-3) 카드 전환 시 햅틱 피드백을 적용해 조작감을 강화
   2-4) 월 예상 수령액이 함께 보이도록 카드 구성 및 계산 로직 보완

3. 근무지 등록 / 수정 UX 개선
   3-1) AddJobView 입력 화면에서 키보드 툴바로 이전 / 다음 필드 이동이 가능하도록 개선
   3-2) 키보드 완료 버튼을 checkmark 형태로 정리해 입력 흐름을 단순화
   3-3) 저장하지 않고 화면을 나갔을 때 수정 내용이 반영되던 버그 수정

4. 근무 상세 및 기록 화면 보완
   4-1) 상세보기 화면에서 기존 근무 시간이 보이지 않던 문제 수정
   4-2) 자율 근무제 환경을 고려해 상세 정보 노출 방식 보완
   4-3) 기록 화면에 삭제 안내 문구를 추가해 사용성 개선

5. 다크 모드 대응
   5-1) 주요 화면 색상 구조를 정리해 다크 모드 1차 대응
   5-2) 위젯 포함 일부 화면의 다크 모드 색상 및 대비 개선
   5-3) 잘못 누적된 패딩 및 레이아웃 문제를 함께 수정

6. 안정성 및 기타 개선
   6-1) 알림 처리 과정에서 발생할 수 있던 크래시 가능성을 줄이도록 참조 구조 개선
   6-2) FAQ 및 도움말 문구를 더 자연스럽게 수정
   6-3) 말풍선 위치, 카드 전환 연출 등 세부 UI 디테일 보정
