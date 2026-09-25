//
//  ScheduleParser.swift
//  AlbaTime
//
//  Created by 이준희 on 1/17/26.
//

import Foundation
import CoreGraphics

final class ScheduleParser: Sendable {
    static let shared = ScheduleParser()
    private init() {}

    func parse(rows: [TextRow], presets: [TimePresetDraft], targetName: String = "",
               referenceDate: Date = Date(), calendar: Calendar = .current) -> [ParsedSchedule] {
        var parser = LegacyScheduleParsing(presets: presets, targetName: targetName,
                                           referenceDate: referenceDate, calendar: calendar)
        return parser.parse(rows)
    }
}

/// Per-image state: no Date() calls or document context shared across requests.
private struct LegacyScheduleParsing {
    private enum Regex {
        static let fullDate = try! NSRegularExpression(
            pattern: #"(?<!\d)(\d{4})\s*[년./-]\s*(\d{1,2})\s*[월./-]\s*(\d{1,2})\s*일?(?!\d)"#)
        // A bare "9-18" is a time range, not a month/day. ISO dates include a year.
        static let monthDay = try! NSRegularExpression(
            pattern: #"(?<![\d:./-])(\d{1,2})\s*[./월]\s*(\d{1,2})\s*일?(?![\d:./~\-–—])"#)
        static let dayOnly = try! NSRegularExpression(
            pattern: #"^\s*(\d{1,2})\s*일?(?:\s*[\(\[]?\s*(?:[월화수목금토일](?:요일)?|MON|TUE|WED|THU|FRI|SAT|SUN)\s*[\)\]]?)?\s*$"#,
            options: .caseInsensitive)
        static let monthHeading = try! NSRegularExpression(
            pattern: #"^(?:(\d{4})\s*(?:년|[./-])\s*)?(\d{1,2})\s*월(?:\s*[^\d]*)?$"#)
        static let time = try! NSRegularExpression(
            pattern: #"(?<![\d:./-])(\d{1,2})(?:\s*[:.;시]\s*(\d{2}))?\s*[~～〜\-–—]\s*(\d{1,2})(?:\s*[:.;시]\s*(\d{2}))?(?![\d:./-])"#)
        static let koreanHour = try! NSRegularExpression(
            pattern: #"(?<![\d:./-])(\d{1,2})\s*시(?:\s*(\d{1,2})\s*분?)?\s*[~～〜\-–—]\s*(\d{1,2})\s*시(?:\s*(\d{1,2})\s*분?)?(?![\d:./-])"#)
    }

    let presets: [TimePresetDraft]
    let targetName: String
    let referenceDate: Date
    let calendar: Calendar
    private var documentYear: Int
    private var documentMonth: Int
    private var hasMonthHeading = false

    init(presets: [TimePresetDraft], targetName: String, referenceDate: Date, calendar: Calendar) {
        self.presets = presets
        self.targetName = targetName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.referenceDate = referenceDate
        self.calendar = calendar
        documentYear = calendar.component(.year, from: referenceDate)
        documentMonth = calendar.component(.month, from: referenceDate)
    }

    private struct Column {
        // Invalid headers still occupy a column; never move their shifts to a neighbour.
        let date: Date?
        let midX: CGFloat
    }

    private struct Shift {
        let start: Int
        let end: Int
        let label: String?
    }

    mutating func parse(_ rows: [TextRow]) -> [ParsedSchedule] {
        var columns: [Column] = []
        var contextDate: Date?
        var activeForTarget = false
        var activeGridForTarget = targetName.isEmpty
        var schedules: [ParsedSchedule] = []

        for row in rows {
            let line = row.fullText
            if updateMonthHeading(line) {
                columns = []
                contextDate = nil
                activeForTarget = false
                continue
            }
            let datedElements = row.elements.compactMap { element -> Column? in
                let date = extractDate(element.text, allowDayOnly: true)
                guard date != nil || containsDateSyntax(element.text)
                    || Regex.dayOnly.firstMatch(in: element.text, range: nsRange(element.text)) != nil else { return nil }
                return Column(date: date, midX: element.midX)
            }
            let shifts = row.elements.flatMap { element in
                extractShifts(element.text).map { (element: element, shift: $0) }
            }
            if datedElements.count >= 2 && shifts.isEmpty {
                columns = datedElements.sorted { $0.midX < $1.midX }
                activeForTarget = false
                activeGridForTarget = targetName.isEmpty
                continue
            }
            let weekdayCandidates = row.elements.compactMap { element -> Column? in
                guard let index = weekdayIndex(element.text),
                      let date = calendar.date(byAdding: .day, value: index, to: monday) else { return nil }
                return Column(date: date, midX: element.midX)
            }
            // "월(Mon)" may be tokenized into two boxes. They represent one
            // column, not two adjacent weekday columns.
            let weekdays = weekdayCandidates.sorted { $0.midX < $1.midX }
                .reduce(into: [Column]()) { unique, candidate in
                    guard !unique.contains(where: { existing in
                        guard let existingDate = existing.date, let candidateDate = candidate.date else { return false }
                        return calendar.isDate(existingDate, inSameDayAs: candidateDate)
                    }) else { return }
                    unique.append(candidate)
                }
            if weekdays.count >= 2 && shifts.isEmpty {
                // A second row of weekday labels must not replace explicit dates.
                if columns.isEmpty { columns = weekdays.sorted { $0.midX < $1.midX } }
                continue
            }

            if !columns.isEmpty {
                let namedHeading = row.elements.contains { isPersonHeading($0.text) }
                    || line.split(whereSeparator: \.isWhitespace).first.map {
                        isPersonHeading(String($0))
                    } == true
                if namedHeading {
                    activeGridForTarget = matchesTarget(line)
                } else if matchesTarget(line) {
                    activeGridForTarget = true
                }
                guard targetName.isEmpty || activeGridForTarget else { continue }
                for (element, shift) in shifts {
                    guard let date = dateColumn(for: element, columns: columns) else { continue }
                    schedules.append(makeSchedule(date: date, shift: shift))
                }
                continue
            }

            // A named heading starts/ends a notice block. An unrelated named
            // row also ends it even if its author did not use an @ mention.
            let matches = matchesTarget(line)
            let hasNamedOwner = row.elements.contains { isPersonHeading($0.text) }
                || line.split(whereSeparator: \.isWhitespace).first.map { isPersonHeading(String($0)) } == true
                || line.contains("@")
            if hasNamedOwner || matches { activeForTarget = matches }
            if let date = extractDate(line, allowDayOnly: shifts.isEmpty) {
                contextDate = date
            } else if containsDateSyntax(line) {
                // An invalid explicit date must not silently inherit yesterday's.
                contextDate = nil
            } else if datedElements.count == 1 {
                contextDate = datedElements.first?.date
            }
            guard targetName.isEmpty || matches || activeForTarget,
                  let date = contextDate else { continue }
            for (_, shift) in shifts {
                schedules.append(makeSchedule(date: date, shift: shift))
            }
        }
        var seen = Set<String>()
        return schedules.sorted { $0.startTime < $1.startTime }.filter {
            seen.insert("\($0.startTime.timeIntervalSince1970)_\($0.endTime.timeIntervalSince1970)").inserted
        }
    }

    private var monday: Date {
        let day = calendar.startOfDay(for: referenceDate)
        return calendar.date(byAdding: .day,
                             value: -((calendar.component(.weekday, from: day) + 5) % 7), to: day) ?? day
    }

    private mutating func updateMonthHeading(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let match = Regex.monthHeading.firstMatch(in: trimmed, range: nsRange(trimmed)),
              let month = number(match, 2, trimmed), (1...12).contains(month) else { return false }
        documentMonth = month
        documentYear = number(match, 1, trimmed) ?? calendar.component(.year, from: referenceDate)
        hasMonthHeading = true
        return true
    }

    private func extractDate(_ text: String, allowDayOnly: Bool) -> Date? {
        let fullMatches = Regex.fullDate.matches(in: text, range: nsRange(text))
        for match in fullMatches {
            if let year = number(match, 1, text), let month = number(match, 2, text),
               let day = number(match, 3, text), let date = strictDate(year: year, month: month, day: day) {
                return date
            }
        }
        // Do not reinterpret a substring of a malformed explicit year/date.
        if !fullMatches.isEmpty { return nil }
        for match in Regex.monthDay.matches(in: text, range: nsRange(text)) {
            guard let month = number(match, 1, text), let day = number(match, 2, text) else { continue }
            if !hasMonthHeading {
                for offset in 0..<7 {
                    if let date = calendar.date(byAdding: .day, value: offset, to: monday),
                       calendar.component(.month, from: date) == month,
                       calendar.component(.day, from: date) == day { return date }
                }
            }
            return strictDate(year: documentYear, month: month, day: day)
        }
        guard allowDayOnly,
              let match = Regex.dayOnly.firstMatch(in: text, range: nsRange(text)),
              let day = number(match, 1, text) else { return nil }
        if !hasMonthHeading {
            // Resolve a selected week crossing a month/year boundary correctly.
            for offset in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: offset, to: monday),
                   calendar.component(.day, from: date) == day { return date }
            }
        }
        return strictDate(year: documentYear, month: documentMonth, day: day)
    }

    private func containsDateSyntax(_ text: String) -> Bool {
        Regex.fullDate.firstMatch(in: text, range: nsRange(text)) != nil
            || Regex.monthDay.firstMatch(in: text, range: nsRange(text)) != nil
    }

    private func strictDate(year: Int, month: Int, day: Int) -> Date? {
        guard (1...9999).contains(year), (1...12).contains(month), (1...31).contains(day),
              let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else { return nil }
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard components.year == year, components.month == month, components.day == day else { return nil }
        return date
    }

    private func extractShifts(_ text: String) -> [Shift] {
        let normalized = compact(text)
        if ["OFF", "0FF", "휴무", "휴무(OFF)", "휴무(0FF)"].contains(normalized) { return [] }
        if let preset = presets.first(where: { compact($0.label) == normalized }) {
            return validShift(start: minutes(preset.startTime), end: minutes(preset.endTime), label: preset.label)
                .map { [$0] } ?? []
        }
        // Character correction is restricted to time extraction, never names,
        // weekday names, or preset labels.
        let cleaned = text.uppercased()
            .replacingOccurrences(of: "O", with: "0")
            .replacingOccurrences(of: "I", with: "1")
            .replacingOccurrences(of: "L", with: "1")
            .replacingOccurrences(of: "；", with: ":")
        let timeShifts: [Shift] = Regex.time.matches(in: cleaned, range: nsRange(cleaned)).compactMap { match in
            guard let startHour = number(match, 1, cleaned), let endHour = number(match, 3, cleaned) else { return nil }
            let startMinute = number(match, 2, cleaned) ?? 0
            let endMinute = number(match, 4, cleaned) ?? 0
            guard (0...23).contains(startHour), (0...59).contains(startMinute),
                  (0...59).contains(endMinute),
                  (0...23).contains(endHour) || (endHour == 24 && endMinute == 0) else { return nil }
            let start = startHour * 60 + startMinute
            let end = endHour * 60 + endMinute
            let label = presets.first { minutes($0.startTime) == start && minutes($0.endTime) == end % 1440 }?.label
            return validShift(start: start, end: end, label: label)
        }
        if !timeShifts.isEmpty { return timeShifts }
        return Regex.koreanHour.matches(in: cleaned, range: nsRange(cleaned)).compactMap { match in
            guard let startHour = number(match, 1, cleaned), let endHour = number(match, 3, cleaned) else { return nil }
            let startMinute = number(match, 2, cleaned) ?? 0
            let endMinute = number(match, 4, cleaned) ?? 0
            guard (0...23).contains(startHour), (0...59).contains(startMinute),
                  (0...59).contains(endMinute),
                  (0...23).contains(endHour) || (endHour == 24 && endMinute == 0) else { return nil }
            let start = startHour * 60 + startMinute
            let end = endHour * 60 + endMinute
            let label = presets.first { minutes($0.startTime) == start && minutes($0.endTime) == end % 1440 }?.label
            return validShift(start: start, end: end, label: label)
        }
    }

    private func validShift(start: Int, end: Int, label: String?) -> Shift? {
        // Equal times are ambiguous; do not invent a 24-hour shift.
        guard start != end else { return nil }
        return Shift(start: start, end: end <= start ? end + 1440 : end, label: label)
    }

    private func makeSchedule(date: Date, shift: Shift) -> ParsedSchedule {
        func at(_ minutes: Int) -> Date {
            let day = calendar.date(byAdding: .day, value: minutes / 1440, to: date) ?? date
            return calendar.date(bySettingHour: minutes % 1440 / 60, minute: minutes % 60, second: 0, of: day) ?? day
        }
        return ParsedSchedule(date: calendar.startOfDay(for: date), startTime: at(shift.start),
                              endTime: at(shift.end), workLabel: shift.label)
    }

    private func matchesTarget(_ text: String) -> Bool {
        guard !targetName.isEmpty else { return false }
        let name = targetName.uppercased().filter { !$0.isWhitespace }
        let pattern = name.map { NSRegularExpression.escapedPattern(for: String($0)) }.joined(separator: #"\s*"#)
        return text.uppercased().range(
            of: #"(?<![가-힣A-Z])"# + pattern + #"(?:\s*(?:알바님|님))?(?![가-힣A-Z])"#,
            options: .regularExpression) != nil
    }

    private func isPersonHeading(_ text: String) -> Bool {
        var name = compact(text).replacingOccurrences(of: "@", with: "")
        for suffix in ["알바님", "님"] where name.hasSuffix(suffix) { name.removeLast(suffix.count) }
        guard !["휴무", "OFF", "0FF", "근무", "일정", "스케줄", "근무표", "오픈", "마감", "미들"].contains(name),
              weekdayIndex(name) == nil,
              !presets.contains(where: { compact($0.label) == name }) else { return false }
        return name.range(of: #"^(?:[가-힣]{2,4}|[A-Z]{2,})$"#, options: .regularExpression) != nil
    }

    private func weekdayIndex(_ text: String) -> Int? {
        let token = compact(text).trimmingCharacters(in: CharacterSet(charactersIn: "()[]"))
        let koreanNames = ["월", "화", "수", "목", "금", "토", "일"]
        let englishNames = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
        for index in koreanNames.indices {
            let korean = koreanNames[index]
            let isKoreanWeekday = token == korean
                || token == korean + "요일"
                || token.hasPrefix(korean + "(")
                || token.hasPrefix(korean + "[")
            let english = englishNames[index]
            let isEnglishWeekday = token == english
                || token == english + "DAY"
                || token.hasPrefix(english + "(")
                || token.hasPrefix(english + "[")
            if isKoreanWeekday || isEnglishWeekday { return index }
        }
        return nil
    }

    private func dateColumn(for element: TextElement, columns: [Column]) -> Date? {
        guard let index = columns.indices.min(by: {
            abs(columns[$0].midX - element.midX) < abs(columns[$1].midX - element.midX)
        }) else { return nil }
        let column = columns[index]
        let gaps = columns.indices.filter { $0 != index }.map { abs(columns[$0].midX - column.midX) }
        guard let gap = gaps.min(), gap > 0,
              abs(column.midX - element.midX) < gap / 2 else { return nil }
        // A line spanning two column centers cannot be assigned to just one day.
        if let box = element.boundingBox,
           columns.filter({ $0.midX >= box.minX && $0.midX <= box.maxX }).count > 1 { return nil }
        return column.date
    }

    private func compact(_ text: String) -> String { text.uppercased().filter { !$0.isWhitespace } }
    private func minutes(_ date: Date) -> Int {
        calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
    }
    private func nsRange(_ text: String) -> NSRange { NSRange(text.startIndex..., in: text) }
    private func number(_ match: NSTextCheckingResult, _ group: Int, _ text: String) -> Int? {
        guard let range = Range(match.range(at: group), in: text) else { return nil }
        return Int(text[range])
    }
}
