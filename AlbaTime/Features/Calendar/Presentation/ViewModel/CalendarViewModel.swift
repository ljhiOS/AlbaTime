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
    let workPlaceID: UUID
    let workPlaceName: String
    let date: Date
    let startTime: Date
    let endTime: Date
    let breakTime: Int
    let estimatedPay: Int
    let hourlyWage: Int

    var timeRange: String {
        "\(startTime.time24h) - \(endTime.time24h)"
    }
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
    private let workRecordSaving: any CalendarWorkRecordSaving
    private let analyticsTracker: any AnalyticsTracking

    init(
        loadCalendarWorkPlaces: any CalendarWorkPlacesLoading,
        workRecordSaving: any CalendarWorkRecordSaving,
        analyticsTracker: any AnalyticsTracking
    ) {
        self.loadCalendarWorkPlaces = loadCalendarWorkPlaces
        self.workRecordSaving = workRecordSaving
        self.analyticsTracker = analyticsTracker
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

    func saveWorkRecord(
        for schedule: CalendarScheduleState,
        startTime: Date,
        endTime: Date
    ) {
        do {
            try workRecordSaving.execute(
                CalendarWorkRecordCommand(
                    workPlaceID: schedule.workPlaceID,
                    date: schedule.date,
                    startTime: startTime,
                    endTime: endTime,
                    breakTime: schedule.breakTime
                )
            )

            analyticsTracker.track(.workTimeChanged)

            load()
        } catch {
            print("근무 시간 저장 실패: \(error)")
        }
    }

    private func updateCache() {
        let calendar = Calendar.current
        var newCache: [Date: [WorkPlace]] = [:]
        let daysInMonth = generateDaysInMonth().compactMap { $0 }

        for date in daysInMonth {
            let dateKey = calendar.startOfDay(for: date)

            for workPlace in workPlaces {
                if ScheduleResolver.resolve(workPlace: workPlace, for: date) != nil {
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

        selectedDateSchedules = scheduled.compactMap { workPlace in
            guard let resolved = ScheduleResolver.resolve(workPlace: workPlace, for: selectedDate) else {
                return nil
            }

            return CalendarScheduleState(
                id: workPlace.id,
                workPlaceID: workPlace.id,
                workPlaceName: workPlace.name,
                date: selectedDate,
                startTime: resolved.startTime,
                endTime: resolved.endTime,
                breakTime: resolved.breakTime,
                estimatedPay: getEstimatedPay(
                    workPlace: workPlace,
                    startTime: resolved.startTime,
                    endTime: resolved.endTime,
                    breakTime: resolved.breakTime
                ),
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

    private func getEstimatedPay(
        workPlace: WorkPlace,
        startTime: Date,
        endTime: Date,
        breakTime: Int
    ) -> Int {
        let tempSchedule = WorkSchedule(
            date: selectedDate,
            startTime: startTime,
            endTime: endTime,
            breakTime: breakTime,
            workPlace: nil
        )
        return SalaryCalculator.calculateDailyPay(
            schedule: tempSchedule,
            hourlyWage: workPlace.hourlyWage,
            includeNightAllowance: workPlace.allowanceType.includesNight
        )
    }

}
