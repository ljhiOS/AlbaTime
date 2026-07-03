//
//  ScheduleParser.swift
//  AlbaTime
//
//  Created by 이준희 on 1/17/26.
//

import Foundation

final class ScheduleParser: Sendable {
    private enum Regex {
        static let date = try? NSRegularExpression(pattern: #"(\d{1,2})\s*[./월-]\s*(\d{1,2})"#)
        static let dayOnly = try? NSRegularExpression(pattern: #"^(\d{1,2})[^\d]*$"#)
        static let timeRange = try? NSRegularExpression(
            pattern: #"(\d{1,2})\s*[:시]\s*(\d{2})\s*[~\-–—]\s*(\d{1,2})\s*[:시]\s*(\d{2})"#
        )
        static let hourRange = try? NSRegularExpression(
            pattern: #"(?<!\d)(\d{1,2})\s*[~\-–—]\s*(\d{1,2})(?!\d)"#
        )
    }

    static let shared = ScheduleParser()
    private init() {}

    private struct DateColumn {
        let date: Date
        let midX: CGFloat
    }

    private struct WeekdayColumn {
        let index: Int // 0:월 ... 6:일
        let midX: CGFloat
    }

    func parse(rows: [TextRow], presets: [WorkTimePreset], targetName: String = "") -> [ParsedSchedule] {
        guard
            let dateRegex = Regex.date,
            let dayOnlyRegex = Regex.dayOnly
        else {
            return []
        }

        var collected: [ParsedSchedule] = []

        collected.append(contentsOf: parseGridAndListRows(
            rows: rows,
            presets: presets,
            targetName: targetName,
            dateRegex: dateRegex,
            dayOnlyRegex: dayOnlyRegex
        ))

        collected.append(contentsOf: parseTargetBlocks(
            rows: rows,
            presets: presets,
            targetName: targetName,
            dateRegex: dateRegex
        ))

        collected.append(contentsOf: parseWeekdayMatrixRows(
            rows: rows,
            presets: presets,
            targetName: targetName
        ))

        return deduplicate(collected)
    }

    // MARK: - Strategy 1: Grid/List

    private func parseGridAndListRows(
        rows: [TextRow],
        presets: [WorkTimePreset],
        targetName: String,
        dateRegex: NSRegularExpression,
        dayOnlyRegex: NSRegularExpression
    ) -> [ParsedSchedule] {
        var results: [ParsedSchedule] = []
        var headerDateColumns: [DateColumn] = []

        for row in rows {
            let rowDates = row.elements.compactMap { el -> DateColumn? in
                if let d = extractDate(from: el.text, regex: dateRegex) {
                    return DateColumn(date: d, midX: el.midX)
                }
                if let d = extractDayOnly(from: el.text, regex: dayOnlyRegex) {
                    return DateColumn(date: d, midX: el.midX)
                }
                return nil
            }

            if rowDates.count >= 3 {
                headerDateColumns = rowDates
                continue
            }

            let rowSpecificDate = rowDates.first?.date
            let isMyRow = targetName.isEmpty || row.elements.contains {
                isSimilarName(target: targetName, recognized: $0.text)
            }
            guard isMyRow else { continue }

            for el in row.elements {
                let text = el.text.trimmingCharacters(in: .whitespacesAndNewlines)
                let norm = normalize(text)

                if extractDate(from: text, regex: dateRegex) != nil { continue }
                if ["OFF", "0FF", "휴무", "휴무(OFF)"].contains(norm) { continue }

                let parsed = parseTokenToSchedule(text: text, presets: presets)
                guard let start = parsed.start, let end = parsed.end else { continue }

                var targetDate: Date?
                if !headerDateColumns.isEmpty,
                   let closest = headerDateColumns.min(by: { abs($0.midX - el.midX) < abs($1.midX - el.midX) }) {
                    targetDate = closest.date
                } else if let rowDate = rowSpecificDate {
                    targetDate = rowDate
                }

                guard let validDate = targetDate else { continue }
                let final = makeSchedule(date: validDate, start: start, end: end, label: parsed.label)
                results.append(final)
            }
        }

        return results
    }

    // MARK: - Strategy 2: Notice/Bullet Block

    private func parseTargetBlocks(
        rows: [TextRow],
        presets: [WorkTimePreset],
        targetName: String,
        dateRegex: NSRegularExpression
    ) -> [ParsedSchedule] {
        guard !targetName.isEmpty else { return [] }

        var results: [ParsedSchedule] = []
        var activeForTarget = false
        var contextDate: Date?

        for row in rows {
            let line = row.fullText

            if let date = extractDate(from: line, regex: dateRegex) {
                contextDate = date
            }

            // "@이준희", "이준희 알바님" 형태를 타깃 블록 시작으로 처리
            if containsTargetName(in: line, targetName: targetName) {
                activeForTarget = true
            } else if line.contains("@"), !containsTargetName(in: line, targetName: targetName) {
                // 다른 사람 멘션 블록 시작 시 타깃 블록 종료
                activeForTarget = false
            }

            guard activeForTarget || containsTargetName(in: line, targetName: targetName) else { continue }

            let parsed = parseTokenToSchedule(text: line, presets: presets)
            guard let start = parsed.start, let end = parsed.end else { continue }

            let date = extractDate(from: line, regex: dateRegex) ?? contextDate
            guard let validDate = date else { continue }
            results.append(makeSchedule(date: validDate, start: start, end: end, label: parsed.label))
        }

        return results
    }

    // MARK: - Strategy 3: Weekday Matrix

    private func parseWeekdayMatrixRows(
        rows: [TextRow],
        presets: [WorkTimePreset],
        targetName: String
    ) -> [ParsedSchedule] {
        guard !targetName.isEmpty else { return [] }

        guard let header = rows.first(where: { weekdayColumns(in: $0).count >= 4 }) else {
            return []
        }
        let columns = weekdayColumns(in: header)
        guard !columns.isEmpty else { return [] }

        guard let targetRow = rows.first(where: { rowContainsTargetName($0, targetName: targetName) }) else {
            return []
        }

        let monday = startOfWeekMonday(from: Date())
        var results: [ParsedSchedule] = []

        for col in columns {
            guard let token = nearestToken(in: targetRow, to: col.midX) else { continue }
            let text = token.trimmingCharacters(in: .whitespacesAndNewlines)
            let norm = normalize(text)
            if text.isEmpty || ["OFF", "0FF", "휴무", "휴무(OFF)"].contains(norm) { continue }

            let parsed = parseTokenToSchedule(text: text, presets: presets)
            guard let start = parsed.start, let end = parsed.end else { continue }

            guard let date = Calendar.current.date(byAdding: .day, value: col.index, to: monday) else { continue }
            results.append(makeSchedule(date: date, start: start, end: end, label: parsed.label))
        }

        return results
    }

    // MARK: - Parsing Helpers

    private func parseTokenToSchedule(text: String, presets: [WorkTimePreset]) -> (start: Date?, end: Date?, label: String?) {
        let norm = normalize(text)

        if let preset = presets.first(where: { normalize($0.label) == norm }) {
            return (preset.startTime, preset.endTime, preset.label)
        }

        if let (s, e) = extractTimeRange(from: text) {
            let start = makeTime(h: s.0, m: s.1)
            let end = makeTime(h: e.0, m: e.1)
            var label: String?
            if let st = start, let et = end {
                label = matchPresetByTime(start: st, end: et, presets: presets)
            }
            return (start, end, label)
        }

        return (nil, nil, nil)
    }

    private func makeSchedule(date: Date, start: Date, end: Date, label: String?) -> ParsedSchedule {
        let finalStart = combine(date: date, time: start)
        var finalEnd = combine(date: date, time: end)
        if finalEnd <= finalStart {
            finalEnd = Calendar.current.date(byAdding: .day, value: 1, to: finalEnd) ?? finalEnd
        }
        return ParsedSchedule(date: date, startTime: finalStart, endTime: finalEnd, workLabel: label)
    }

    private func extractDate(from text: String, regex: NSRegularExpression) -> Date? {
        guard let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
        let month = Int((text as NSString).substring(with: match.range(at: 1))) ?? 0
        let day = Int((text as NSString).substring(with: match.range(at: 2))) ?? 0
        return makeDate(month: month, day: day)
    }

    private func extractDayOnly(from text: String, regex: NSRegularExpression) -> Date? {
        let num = text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard let day = Int(num), (1...31).contains(day) else { return nil }
        let month = Calendar.current.component(.month, from: Date())
        return makeDate(month: month, day: day)
    }

    private func extractTimeRange(from text: String) -> ((Int, Int), (Int, Int))? {
        let cleaned = normalizeTimeToken(text)

        if let rangeRegex = Regex.timeRange,
           let m = rangeRegex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)) {
            let h1 = Int((cleaned as NSString).substring(with: m.range(at: 1))) ?? -1
            let m1 = Int((cleaned as NSString).substring(with: m.range(at: 2))) ?? -1
            let h2 = Int((cleaned as NSString).substring(with: m.range(at: 3))) ?? -1
            let m2 = Int((cleaned as NSString).substring(with: m.range(at: 4))) ?? -1
            guard let start = normalizedHM(hour: h1, minute: m1),
                  let end = normalizedHM(hour: h2, minute: m2) else { return nil }
            return (start, end)
        }

        // "9~18" 같은 단순 시간 범위 포맷 fallback
        if let hourRegex = Regex.hourRange,
           let m = hourRegex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)) {
            let h1 = Int((cleaned as NSString).substring(with: m.range(at: 1))) ?? -1
            let h2 = Int((cleaned as NSString).substring(with: m.range(at: 2))) ?? -1
            guard let start = normalizedHM(hour: h1, minute: 0),
                  let end = normalizedHM(hour: h2, minute: 0) else { return nil }
            return (start, end)
        }

        return nil
    }

    private func normalizedHM(hour: Int, minute: Int) -> (Int, Int)? {
        if hour == 24 && minute == 0 { return (0, 0) }
        guard (0...23).contains(hour), (0...59).contains(minute) else { return nil }
        return (hour, minute)
    }

    private func normalize(_ text: String) -> String {
        text.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "O", with: "0")
            .replacingOccurrences(of: "I", with: "1")
            .replacingOccurrences(of: "L", with: "1")
            .replacingOccurrences(of: "알바님", with: "")
            .replacingOccurrences(of: "님", with: "")
    }

    private func normalizeTimeToken(_ text: String) -> String {
        text.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "O", with: "0")
            .replacingOccurrences(of: "I", with: "1")
            .replacingOccurrences(of: "L", with: "1")
            .replacingOccurrences(of: "；", with: ":")
            .replacingOccurrences(of: ".", with: ":")
            .replacingOccurrences(of: ";", with: ":")
            .replacingOccurrences(of: "〜", with: "~")
            .replacingOccurrences(of: "～", with: "~")
    }

    private func containsTargetName(in text: String, targetName: String) -> Bool {
        let t = normalizeNameToken(targetName)
        let s = normalizeNameToken(text)
        guard !t.isEmpty, !s.isEmpty else { return false }
        return s.contains(t) || levenshteinDistance(t, s) <= max(1, t.count / 3)
    }

    private func rowContainsTargetName(_ row: TextRow, targetName: String) -> Bool {
        row.elements.contains { isSimilarName(target: targetName, recognized: $0.text) } || containsTargetName(in: row.fullText, targetName: targetName)
    }

    private func normalizeNameToken(_ s: String) -> String {
        let normalized = normalize(s)
        return normalized.replacingOccurrences(of: #"[^가-힣A-Z0-9]"#, with: "", options: .regularExpression)
    }

    private func isSimilarName(target: String, recognized: String) -> Bool {
        let t = normalizeNameToken(target)
        let r = normalizeNameToken(recognized)
        guard !t.isEmpty, !r.isEmpty else { return false }
        return r.contains(t) || levenshteinDistance(t, r) <= (t.count <= 2 ? 1 : 2)
    }

    private func makeDate(month: Int, day: Int) -> Date? {
        var c = DateComponents()
        c.year = Calendar.current.component(.year, from: Date())
        c.month = month
        c.day = day
        return Calendar.current.date(from: c)
    }

    private func makeTime(h: Int, m: Int) -> Date? {
        Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: Date())
    }

    private func combine(date: Date, time: Date) -> Date {
        let comp = Calendar.current.dateComponents([.hour, .minute], from: time)
        return Calendar.current.date(bySettingHour: comp.hour ?? 0, minute: comp.minute ?? 0, second: 0, of: date) ?? date
    }

    private func matchPresetByTime(start: Date, end: Date, presets: [WorkTimePreset]) -> String? {
        let s = Calendar.current.component(.hour, from: start) * 60 + Calendar.current.component(.minute, from: start)
        let e = Calendar.current.component(.hour, from: end) * 60 + Calendar.current.component(.minute, from: end)

        for p in presets {
            let ps = Calendar.current.component(.hour, from: p.startTime) * 60 + Calendar.current.component(.minute, from: p.startTime)
            let pe = Calendar.current.component(.hour, from: p.endTime) * 60 + Calendar.current.component(.minute, from: p.endTime)
            if abs(s - ps) <= 30 && abs(e - pe) <= 30 {
                return p.label
            }
        }
        return nil
    }

    // MARK: - Weekday Helpers

    private func weekdayColumns(in row: TextRow) -> [WeekdayColumn] {
        row.elements.compactMap { el in
            guard let idx = weekdayIndex(from: el.text) else { return nil }
            return WeekdayColumn(index: idx, midX: el.midX)
        }
        .sorted { $0.midX < $1.midX }
    }

    private func weekdayIndex(from text: String) -> Int? {
        let t = normalize(text)
        if t.contains("MON") || t == "월" || t.contains("월(") { return 0 }
        if t.contains("TUE") || t == "화" || t.contains("화(") { return 1 }
        if t.contains("WED") || t == "수" || t.contains("수(") { return 2 }
        if t.contains("THU") || t == "목" || t.contains("목(") { return 3 }
        if t.contains("FRI") || t == "금" || t.contains("금(") { return 4 }
        if t.contains("SAT") || t == "토" || t.contains("토(") { return 5 }
        if t.contains("SUN") || t == "일" || t.contains("일(") { return 6 }
        return nil
    }

    private func nearestToken(in row: TextRow, to midX: CGFloat) -> String? {
        row.elements
            .min(by: { abs($0.midX - midX) < abs($1.midX - midX) })
            .flatMap { candidate in
                abs(candidate.midX - midX) <= 0.09 ? candidate.text : nil
            }
    }

    private func startOfWeekMonday(from date: Date) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date) // 1:일 ... 7:토
        let daysToSubtract = (weekday + 5) % 7
        let todayStart = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: todayStart) ?? todayStart
    }

    // MARK: - Dedupe

    private func deduplicate(_ schedules: [ParsedSchedule]) -> [ParsedSchedule] {
        let calendar = Calendar.current
        var seen = Set<String>()
        var result: [ParsedSchedule] = []

        for s in schedules.sorted(by: { $0.startTime < $1.startTime }) {
            let day = calendar.startOfDay(for: s.date).timeIntervalSince1970
            let sh = calendar.component(.hour, from: s.startTime)
            let sm = calendar.component(.minute, from: s.startTime)
            let eh = calendar.component(.hour, from: s.endTime)
            let em = calendar.component(.minute, from: s.endTime)
            let key = "\(Int(day))_\(sh)_\(sm)_\(eh)_\(em)"
            if seen.contains(key) { continue }
            seen.insert(key)
            result.append(s)
        }
        return result
    }

    private func levenshteinDistance(_ a: String, _ b: String) -> Int {
        let aa = Array(a)
        let bb = Array(b)
        if aa.isEmpty { return bb.count }
        if bb.isEmpty { return aa.count }

        var prev = Array(0...bb.count)
        for (i, ca) in aa.enumerated() {
            var cur = [i + 1]
            for (j, cb) in bb.enumerated() {
                cur.append(ca == cb ? prev[j] : min(prev[j], prev[j + 1], cur[j]) + 1)
            }
            prev = cur
        }
        return prev.last ?? 0
    }
}
