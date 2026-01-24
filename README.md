## AlbaTime (알바타임)
AlbaTime은 아르바이트 근무 일정을 관리하고, 복잡한 급여 계산(주휴, 야간, 연장 수당 및 세금)을 자동으로 처리하여 예상 월급을 시각화해 주는 iOS 애플리케이션입니다.

## 주요 기능 (Key Features)

```text
1. 정교한 급여 계산 (Salary Calculation)
사용자가 설정한 근무지 정보를 바탕으로 예상 급여를 실시간으로 계산합니다. (SalaryCalculator.swift)
기본급 계산: 시급 × 근무 시간
주휴수당 자동 적용: 주 15시간 이상 근무 시 주휴수당 자동 산정 (법정 기준 준수)
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
│   ├── AlbaTimeApp.swift       # 앱 진입점 및 SwiftData 컨테이너 설정
│   └── NotificationManager.swift
├── Model
│   ├── WorkPlace.swift         # 근무지 모델 (SwiftData)
│   └── MonthlyRecord.swift     # 월별 기록 모델
├── ViewModel
│   ├── PayViewModel.swift      # 급여 뷰모델
│   ├── CalendarViewModel.swift
│   └── AddJobViewModel.swift
├── View
│   ├── Calendar/               # 캘린더 관련 뷰
│   ├── Pay/                    # 급여 대시보드 뷰
│   ├── Job/                    # 근무지 추가/목록 뷰
│   └── Settings/               # 설정 뷰
└── Extensions
    ├── SalaryCalculator.swift  # 급여 계산 핵심 로직 (Static Method)
    └── Date+Helper.swift
```

<img width="1300" height="1000" alt="Untitled diagram-2026-01-24-111206" src="https://github.com/user-attachments/assets/e0294aba-4e14-430a-a923-04d58ed31c18" />
<img width="300" height="800" alt="Untitled diagram-2026-01-24-132737" src="https://github.com/user-attachments/assets/d0264250-28aa-4449-bfa0-c6b6e57617fa" />

## 실제 구현 화면
<img width="250" alt="IMG_1588" src="https://github.com/user-attachments/assets/cf661780-95c6-4d0c-ad4e-b6193acb1e58" /> <img width="250" alt="Simulator Screenshot - iPhone 17 Pro - 2026-01-13 at 16 07 15" src="https://github.com/user-attachments/assets/bff06303-6946-47a5-88d5-375d6859fc32" /> <img width="250" alt="Simulator Screenshot - iPhone 17 Pro - 2026-01-13 at 16 07 25" src="https://github.com/user-attachments/assets/fa657240-ff38-4a8f-941f-ea152237369d" /> <img width="250" alt="Simulator Screenshot - iPhone 17 Pro - 2026-01-13 at 16 07 32" src="https://github.com/user-attachments/assets/425c44a6-79f0-47d3-be62-150bc3c53ff8" />



## V1.0 앱스토어 배포 기간
2025.12.8 ~ 2025.1.13

## V1.1.0 앱 스토어 배포기간
2025.1.13 ~ 2025.1.24

업데이트
1. visionAi 기반 ai ocr engine 탑재
2. 고정, 자율 스케줄 따로 저장가능하도록 업데이트
