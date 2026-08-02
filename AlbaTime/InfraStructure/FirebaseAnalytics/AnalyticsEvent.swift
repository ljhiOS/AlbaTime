//
//  AnalyticsEvent.swift
//  AlbaTime
//
//  Created by 이준희 on 8/2/26.
//

enum AnalyticsEvent: Sendable {
    // 스케줄 상세보기 확인
    case scheduleDetailViewed

    // 근무지 수정
    case workplaceEdit

    // 고정 근무지 저장
    case fixedWorkplaceSaved

    // 고정 근무지 생성 오픈
    case fixedWorkplaceCreateOpened

    // 비고정 근무지 저장
    case flexibleWorkplaceSaved

    // 비고정 근무지 생성 오픈
    case flexibleWorkplaceCreateOpened

    // AI 스케줄 오픈
    case aiScheduleOpened

    // AI 스케줄 저장
    case aiScheduleSaved

    // 수기추가 스케줄 버튼 클릭
    case manualScheduleClick

    // 수기추가 스케줄 저장
    case manualScheduleSaved

    // 월별 실제 급여 저장
    case monthlyIncomeSaved

    // 누적 - 예상 탭 사용
    case salaryModeChanged

    // 근무 시간 조정
    case workTimeChanged
}
