//
//  ScheduleParser.swift
//  AlbaTime
//
//  Created by 이준희 on 1/17/26.
//

import Foundation

final class ScheduleParser {

    static let shared = ScheduleParser()
    private init() {}

    private struct DateColumn {
        let date: Date
        let midX: CGFloat
    }

    private func normalize(_ text: String) -> String {
        text.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "O", with: "0")
            .replacingOccurrences(of: "I", with: "1")
            .replacingOccurrences(of: "L", with: "1")
    }

    func parse(rows: [TextRow], presets: [WorkTimePreset], targetName: String = "" ) -> [ParsedSchedule] {

        var results: [ParsedSchedule] = []
        var headerDateColumns: [DateColumn] = [] // 달력형(Grid)일 때 사용

        // 정규식
        let dateRegex = try! NSRegularExpression(pattern: #"(\d{1,2})\s*[./월-]\s*(\d{1,2})"#)
        // "1/20 (월)" 같은 패턴도 잡기 위해 뒤에 문자가 와도 허용
        let dayOnlyRegex = try! NSRegularExpression(pattern: #"^(\d{1,2})[^\d]*$"#)
        let timeRegex = try! NSRegularExpression(pattern: #"(\d{1,2})(?:\s*[:;.,시\s]\s*(\d{2}))?"#)

        for row in rows {

            // 1️⃣ 이 줄에 있는 모든 날짜 찾기
            let rowDates = row.elements.compactMap { el -> DateColumn? in
                if let d = extractDate(from: el.text, regex: dateRegex) {
                    return DateColumn(date: d, midX: el.midX)
                }
                if let d = extractDayOnly(from: el.text, regex: dayOnlyRegex) {
                    return DateColumn(date: d, midX: el.midX)
                }
                return nil
            }

            // [Grid 모드] 한 줄에 날짜가 3개 이상이면 -> 달력 헤더로 인식하고 저장
            if rowDates.count >= 3 {
                headerDateColumns = rowDates
                continue
            }
            
            // 🔥 [List 모드] 현재 줄의 맨 앞(왼쪽)에 날짜가 하나 있다면 -> 리스트형 날짜로 인식
            // (이미지의 1/20, 1/21 같은 경우)
            let rowSpecificDate = rowDates.first?.date

            // 2️⃣ 내 이름이 포함된 줄인지 확인 (이름이 없으면 모든 줄 대상)
            let isMyRow = targetName.isEmpty ||
                row.elements.contains { isSimilarName(target: targetName, recognized: $0.text) }

            guard isMyRow else { continue }

            // 3️⃣ 시간/프리셋 파싱
            for el in row.elements {
                let text = el.text.trimmingCharacters(in: .whitespaces)
                let norm = normalize(text)

                // 날짜 텍스트 자체는 스킵
                if extractDate(from: text, regex: dateRegex) != nil { continue }
                if ["OFF", "0FF", "휴무"].contains(norm) { continue }

                var start: Date?
                var end: Date?
                var label: String?

                // A. 프리셋 매칭
                if let preset = presets.first(where: { normalize($0.label) == norm }) {
                    start = preset.startTime
                    end = preset.endTime
                    label = preset.label
                }
                // B. 시간 텍스트 파싱
                else if let (s, e) = extractTimeRange(from: text, regex: timeRegex) {
                    start = makeTime(h: s.0, m: s.1)
                    end = makeTime(h: e.0, m: e.1)
                    if let s = start, let e = end {
                        label = matchPresetByTime(start: s, end: e, presets: presets)
                    }
                }

                // C. 날짜 매핑 (가장 중요!)
                if let s = start, let e = end {
                    var targetDate: Date?
                    
                    if !headerDateColumns.isEmpty {
                        // [Grid 모드] 저장해둔 기둥(Column) 좌표와 비교해서 날짜 찾기
                        if let closestCol = headerDateColumns.min(by: { abs($0.midX - el.midX) < abs($1.midX - el.midX) }) {
                            targetDate = closestCol.date
                        }
                    } else if let rowDate = rowSpecificDate {
                        // 🔥 [List 모드] 현재 줄에 있는 날짜 사용 (이미지 케이스)
                        targetDate = rowDate
                    }
                    
                    // 날짜를 찾았으면 결과 저장
                    if let validDate = targetDate {
                        let finalStart = combine(date: validDate, time: s)
                        var finalEnd = combine(date: validDate, time: e)

                        if finalEnd < finalStart {
                            finalEnd = Calendar.current.date(byAdding: .day, value: 1, to: finalEnd)!
                        }

                        results.append(ParsedSchedule(
                            date: validDate,
                            startTime: finalStart,
                            endTime: finalEnd,
                            scheduleName: label
                        ))
                    }
                }
            }
        }
        return results
    }

    // MARK: - Helpers
    
    private func extractDate(from text: String, regex: NSRegularExpression) -> Date? {
        guard let m = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
        let month = Int((text as NSString).substring(with: m.range(at: 1))) ?? 0
        let day = Int((text as NSString).substring(with: m.range(at: 2))) ?? 0
        return makeDate(month: month, day: day)
    }

    private func extractDayOnly(from text: String, regex: NSRegularExpression) -> Date? {
        let num = text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard let day = Int(num), (1...31).contains(day) else { return nil }
        let month = Calendar.current.component(.month, from: Date())
        return makeDate(month: month, day: day)
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
        let t = Calendar.current.dateComponents([.hour, .minute], from: time)
        return Calendar.current.date(
            bySettingHour: t.hour ?? 0,
            minute: t.minute ?? 0,
            second: 0,
            of: date
        )!
    }

    private func extractTimeRange(from text: String, regex: NSRegularExpression) -> ((Int, Int), (Int, Int))? {
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        guard matches.count >= 2 else { return nil }

        func parse(_ m: NSTextCheckingResult) -> (Int, Int) {
            let h = Int((text as NSString).substring(with: m.range(at: 1))) ?? 0
            let mStr = m.range(at: 2).location != NSNotFound
                ? (text as NSString).substring(with: m.range(at: 2))
                : "0"
            return (h, Int(mStr) ?? 0)
        }
        return (parse(matches[0]), parse(matches[1]))
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

    private func levenshteinDistance(_ a: String, _ b: String) -> Int {
        var last = Array(0...b.count)
        for (i, ca) in a.enumerated() {
            var cur = [i + 1]
            for (j, cb) in b.enumerated() {
                cur.append(ca == cb ? last[j] : min(last[j], last[j + 1], cur[j]) + 1)
            }
            last = cur
        }
        return last.last!
    }

    private func isSimilarName(target: String, recognized: String) -> Bool {
        let t = target.replacingOccurrences(of: " ", with: "")
        let r = recognized.replacingOccurrences(of: " ", with: "")
        return r.contains(t) || levenshteinDistance(t, r) <= (t.count <= 2 ? 1 : 2)
    }
}
