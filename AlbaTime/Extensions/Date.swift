import SwiftUI

extension Date {
    
    // 🔥 [핵심] static으로 선언해서 포맷터를 '한 번만' 생성 (속도 100배 향상)
    private static let kWeekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "E"
        return f
    }()
    
    private static let kFullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E)"
        return f
    }()
    
    private static let kMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월"
        return f
    }()

    // MARK: - 날짜 계산 Helpers
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
    
    // MARK: - 포맷팅 (최적화됨)
    var koreanWeekday: String {
        return Self.kWeekdayFormatter.string(from: self)
    }
    
    func format(_ format: String) -> String {
        if format == "yyyy년 M월" { return Self.kMonthFormatter.string(from: self) }
        if format == "M월 d일 (E)" { return Self.kFullDateFormatter.string(from: self) }
        
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: self)
    }
    
    static func makeTime(_ hour: Int, _ minute: Int) -> Date {
        let now = Date()
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
    }
}
