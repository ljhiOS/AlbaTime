//
//  CalendarViewModel.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI

// View가 WorkPlace 전체에 의존하지 않도록 날짜 셀에 필요한 값만 담습니다.
struct CalendarDayState {
    let date: Date
    let hasWork: Bool
}

// View가 WorkPlace/급여 계산 로직을 알지 않도록 선택일 근무 표시값만 담습니다.
struct CalendarScheduleState: Identifiable {
    let id: UUID
    let workPlaceName: String
    let timeRange: String
    let estimatedPay: Int
    let hourlyWage: Int
}

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var currentMonth: Date = Date()
    @Published var selectedDate: Date = Date()
    
    @Published private(set) var dayStates: [Date: CalendarDayState] = [:]
    @Published private(set) var selectedDateSchedules: [CalendarScheduleState] = []
    @Published private(set) var selectedDateTotalPay: Int = 0
    
    private var workPlaces: [WorkPlace] = []
    private var scheduleCache: [Date : [WorkPlace]] = [:]
    private let loadCalendarWorkPlaces: any CalendarWorkPlacesLoading
    
    init(loadCalendarWorkPlaces: any CalendarWorkPlacesLoading) {
        self.loadCalendarWorkPlaces = loadCalendarWorkPlaces
    }
    
    // 달력 날짜 생성
    func generateDaysInMonth() -> [Date?] {
        let start = currentMonth.startOfMonth()
        let daysInMonth = start.daysInMonth()
        let startDayOfWeek = start.startDayOfWeek()
        
        var days: [Date?] = []
        for _ in 0..<(startDayOfWeek - 1) { days.append(nil) }
        for i in 0..<daysInMonth {
            if let date = Calendar.current.date(byAdding: .day, value: i, to: start) {
                days.append(date)
            }
        }
        return days
    }
    
    func load() {
        do {
            workPlaces = try loadCalendarWorkPlaces.execute()
            updateCache()
        } catch {
            print("캘린더 데이터 로드 실패: \(error)")
        }
    }
    
    func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newDate
            load()
        }
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date
        updateSelectedDateSchedules()
    }
    
    func hasWork(on date: Date) -> Bool {
        let key = Calendar.current.startOfDay(for: date)
        return dayStates[key]?.hasWork ?? false
    }
    
    func applyPickedYearMonth(year: Int, month: Int) {
        let calendar = Calendar.current
        var comp = calendar.dateComponents([.hour, .minute, .second], from: currentMonth)
        comp.year = year
        comp.month = month
        comp.day = 1
        
        if let date = calendar.date(from: comp) {
            currentMonth = date
            load()
        }
    }

    private func updateCache() {
        let calendar = Calendar.current
        var newCache: [Date: [WorkPlace]] = [:]
        
        // 이번 달의 시작과 끝 날짜 구하기 (범위 필터링용)
        let startOfMonth = currentMonth.startOfMonth()
        guard let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)?.addingTimeInterval(-1) else { return }
        
        // 1. [자율 근무 & 개별 기록] 처리 (데이터 -> 날짜 매핑 방식)
        for workPlace in workPlaces {
            // 이번 달에 해당하는 스케줄만 필터링 (속도 향상)
            let monthSchedules = workPlace.workSchedules.filter {
                $0.date >= startOfMonth && $0.date <= endOfMonth
            }
            
            for schedule in monthSchedules {
                let dateKey = calendar.startOfDay(for: schedule.date)
                newCache[dateKey, default: []].append(workPlace)
            }
        }
        
        // 2. [고정 근무] 처리 (패턴 반복)
        let daysInMonth = generateDaysInMonth().compactMap { $0 }
        
        for date in daysInMonth {
            let dateKey = calendar.startOfDay(for: date)
            let weekdayStr = date.koreanWeekday
            
            for workPlace in workPlaces where workPlace.workType == .fixed {
                if workPlace.hasAIOverrideInWeek(containing: date) {
                    let hasActualWorkOnThatDay = workPlace.workSchedules.contains {
                        calendar.isDate($0.date, inSameDayAs: date)
                    }
                    if !hasActualWorkOnThatDay {
                        continue
                    }
                }
                // 이미 위에서 AI 스케줄로 등록된 경우(Override), 중복 추가 방지
                if let existingWorkPlaces = newCache[dateKey], existingWorkPlaces.contains(where: { $0.id == workPlace.id }) {
                    continue
                }
                
                // 고정 스케줄 확인
                let hasFixedSchedule = workPlace.regularSchedules.contains { $0.dayOfWeek == weekdayStr }
                let hasSimpleFixed = workPlace.regularSchedules.isEmpty && workPlace.defaultDays.contains(weekdayStr)
                
                if hasFixedSchedule || hasSimpleFixed {
                    newCache[dateKey, default: []].append(workPlace)
                }
            }
        }
        
        scheduleCache = newCache
        
        dayStates = Dictionary(
            uniqueKeysWithValues: daysInMonth.map { date in
                let key = calendar.startOfDay(for: date)
                return (
                    key,
                    CalendarDayState(
                        date: date,
                        hasWork: !(newCache[key] ?? []).isEmpty
                    )
                )
            }
        )
        
        updateSelectedDateSchedules()
    }
    
    private func updateSelectedDateSchedules() {
        let scheduled = getScheduledWorkPlaces(for: selectedDate)
        
        selectedDateSchedules = scheduled.map { workPlace in
            CalendarScheduleState(
                id: workPlace.id,
                workPlaceName: workPlace.name,
                timeRange: getWorkTimeRange(for: workPlace, on: selectedDate),
                estimatedPay: getEstimatedPay(for: workPlace, on: selectedDate),
                hourlyWage: workPlace.hourlyWage
            )
        }
        
        selectedDateTotalPay = selectedDateSchedules
            .map(\.estimatedPay)
            .reduce(0, +)
    }
    
    // 캐시에서 즉시 조회 (매우 빠름)
    private func getScheduledWorkPlaces(for date: Date) -> [WorkPlace] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return scheduleCache[startOfDay] ?? []
    }
    
    private func getEstimatedPay(for workPlace: WorkPlace, on date: Date) -> Int {
        guard let schedule = workPlace.getSchedule(for: date) else { return 0 }
        
        let tempSchedule = WorkSchedule(
            date: date,
            startTime: schedule.startTime,
            endTime: schedule.endTime,
            breakTime: workPlace.defaultRestTime ?? 0,
            workPlace: nil
        )
        return SalaryCalculator.calculateDailyPay(
            schedule: tempSchedule,
            hourlyWage: workPlace.hourlyWage,
            includeNightAllowance: workPlace.allowanceType.includesNight
        )
    }
    
    private func getWorkTimeRange(for workPlace: WorkPlace, on date: Date) -> String {
        if let schedule = workPlace.getSchedule(for: date) {
            return "\(schedule.startTime.time24h) - \(schedule.endTime.time24h)"
        }
        return "-"
    }
}
