import Foundation

struct AIListMonthKey: Hashable, Identifiable {
    let year: Int
    let month: Int

    var id: String { "\(year)-\(month)" }
}

struct AIListWeekItem: Identifiable {
    let start: Date
    let end: Date
    let count: Int

    var id: Date { start }
}
