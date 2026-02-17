import Foundation

struct SharedShift: Codable {
    let workplaceName: String
    let startTimestamp: TimeInterval
    let endTimestamp: TimeInterval?
    let plannedHours: Double?
}

enum NextShiftSharedKeys {
    static let appGroupID = "group.com.junhee.AlbaTime"
    static let shiftsKey = "upcomingShifts"
}

protocol NextShiftWidgetRepository {
    func read() -> WidgetModel
    func readUpcoming() -> [WidgetModel]
}

struct UserDefaultsNextShiftWidgetRepository: NextShiftWidgetRepository {
    func read() -> WidgetModel {
        let models = readUpcoming()
        guard let next = models.first else {
            return WidgetModel(workplaceName: "근무 없음", shiftStart: nil, shiftEnd: nil, plannedHours: nil)
        }
        return next
    }

    func readUpcoming() -> [WidgetModel] {
        let nowTs = Date().timeIntervalSince1970
        return decodeShifts()
            .filter { $0.startTimestamp > nowTs }
            .map { shift in
                WidgetModel(
                    workplaceName: shift.workplaceName,
                    shiftStart: Date(timeIntervalSince1970: shift.startTimestamp),
                    shiftEnd: shift.endTimestamp.map { Date(timeIntervalSince1970: $0) },
                    plannedHours: shift.plannedHours
                )
            }
    }

    private func decodeShifts() -> [SharedShift] {
        let defaults = UserDefaults(suiteName: NextShiftSharedKeys.appGroupID)
        guard
            let data = defaults?.data(forKey: NextShiftSharedKeys.shiftsKey),
            let shifts = try? JSONDecoder().decode([SharedShift].self, from: data)
        else {
            return []
        }
        return shifts.sorted { $0.startTimestamp < $1.startTimestamp }
    }
}
