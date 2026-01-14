// 로직: 데이터 가공, 계산

import SwiftUI

class CalendarViewModel: ObservableObject {
    @Published var currentMonth: Date = Date() // 보고 있는 달
    @Published var selectedDate: Date = Date() // 선택한 날짜
    
    // 달력 날짜 생성 (빈칸 포함)
    func generateDaysInMonth() -> [Date?] {
        let start = currentMonth.startOfMonth()
        let daysInMonth = start.daysInMonth()
        let startDayOfWeek = start.startDayOfWeek()
        
        var days: [Date?] = []
        
        // 1일 앞 빈칸
        for _ in 0..<(startDayOfWeek - 1) {
            days.append(nil)
        }
        
        // 날짜 채우기
        for i in 0..<daysInMonth {
            if let date = Calendar.current.date(byAdding: .day, value: i, to: start) {
                days.append(date)
            }
        }
        return days
    }
    
    // 월 변경
    func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    // MARK: - 스케줄 관련 로직
    
    // 1. 선택된 날짜(요일)에 일하는 알바만 필터링
    func getScheduledWorkplaces(for date: Date, allWorkplaces: [Workplace]) -> [Workplace] {
        let dayString = date.koreanWeekday // "월", "화"...
        
        return allWorkplaces.filter { workplace in
            // "월/수/금" 문자열에 오늘 요일이 포함되어 있는지 확인
            let days = workplace.defaultDays
            return days.contains(dayString)
        }
    }
    
    // 2. 특정 알바의 예상 급여 가져오기 (계산기 사용)
    func getEstimatedPay(for workplace: Workplace) -> Int {
        return SalaryCalculator.calculateExpectedPay(workplace: workplace)
    }
    
    // 3. 하루 총 예상 급여 가져오기
    func getTotalEstimatedPay(for date: Date, allWorkplaces: [Workplace]) -> Int {
        let scheduled = getScheduledWorkplaces(for: date, allWorkplaces: allWorkplaces)
        return scheduled
            .map { SalaryCalculator.calculateExpectedPay(workplace: $0) }
            .reduce(0, +)
    }
    
    // 4. 근무 시간 문자열 (표시용)
    func getWorkTimeRange(for workplace: Workplace) -> String {
        let start = workplace.defaultStartTime.format("HH:mm")
        let end = workplace.defaultEndTime.format("HH:mm")
        return "\(start) - \(end)"
    }
}
