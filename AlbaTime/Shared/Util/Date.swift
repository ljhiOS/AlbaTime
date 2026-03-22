import SwiftUI

extension Date {
    
    // 포맷터 재사용으로 생성 비용을 줄인다.
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

    private static let kTime24Formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "HH:mm"
        return f
    }()

    private static let kMonthDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M/d"
        return f
    }()

    private static let kMonthDayWeekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M/d (E)"
        return f
    }()

    private static let kPolicyDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월 d일"
        return f
    }()

    // MARK: - 날짜 계산 Helpers
    func startOfMonth() -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }
    
    func daysInMonth() -> Int {
        Calendar.current.range(of: .day, in: .month, for: self)?.count ?? 0
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

    var koreanFullDate: String {
        return Self.kFullDateFormatter.string(from: self)
    }

    var koreanMonthTitle: String {
        return Self.kMonthFormatter.string(from: self)
    }

    var time24h: String {
        return Self.kTime24Formatter.string(from: self)
    }

    var monthDayText: String {
        return Self.kMonthDayFormatter.string(from: self)
    }

    var monthDayWeekdayText: String {
        return Self.kMonthDayWeekdayFormatter.string(from: self)
    }

    var policyDateText: String {
        return Self.kPolicyDateFormatter.string(from: self)
    }
    
    func format(_ format: String) -> String {
        if format == "yyyy년 M월" { return Self.kMonthFormatter.string(from: self) }
        if format == "M월 d일 (E)" { return Self.kFullDateFormatter.string(from: self) }
        if format == "HH:mm" { return Self.kTime24Formatter.string(from: self) }
        if format == "M/d" { return Self.kMonthDayFormatter.string(from: self) }
        if format == "M/d (E)" { return Self.kMonthDayWeekdayFormatter.string(from: self) }
        if format == "yyyy년 M월 d일" { return Self.kPolicyDateFormatter.string(from: self) }
        if format == "E" { return Self.kWeekdayFormatter.string(from: self) }
        
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
