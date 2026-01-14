


// 날짜계산 편의용 date 확장
import SwiftUI

extension Date {
    func startOfMonth() -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self))!
    }
    
    func daysInMonth() -> Int {
        Calendar.current.range(of: .day, in: .month, for: self)!.count
    }
    
    func startDayOfWeek() -> Int {
        Calendar.current.component(.weekday, from: self.startOfMonth())
    }
    
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }
    
    func isSameMonth(as date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, equalTo: date, toGranularity: .month)
    }
    // MARK: - 2. 포맷팅 관련 (강화됨)
    func format(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: self)
    }
    
    var koreanWeekday: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "E" // "월", "화"
        return formatter.string(from: self)
    }
    
    // MARK: - 3. 시간 생성 및 조작 (여기가 중요!)
    
    // 기존 함수 유지 (프리뷰 등에서 사용)
    static func makeTime(_ hour: Int, _ minute: Int) -> Date {
        let now = Date()
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
    }
}
