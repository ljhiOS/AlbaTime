//
//  WidgetViewModel.swift
//  AlbaTime
//
//  Created by 이준희 on 2/6/26.
//

import Foundation

//struct 이유: 상태를 생성하거나 변경하지 않기에
//위젯의 뷰가 바뀌는 것은 상태가 바뀌는 것이 아닌 미래 엔트리를 보여주는 것
//왜 그런가? 배터리 때문이라고 한다 따라서 시스템이 정해진 시간에만 업데이트를 허용한다 -> 위젯은 계속 살아있으면 안된다
//위젯은 상태 변화로 화면을 바꾸는 시스템이 아닌 시간표대로 스냅샷을 교체하는 시스템
struct WidgetViewModel {
    private let model: WidgetModel
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    init(model: WidgetModel) {
        self.model = model
    }

    var title: String { "다음 근무" }
    var workplaceText: String { model.workplaceName }

    var primaryTimeText: String {
        guard let shiftStart = model.shiftStart else { return "--:--" }
        return Self.timeFormatter.string(from: shiftStart)
    }

    var scheduleLabelText: String {
        guard model.shiftStart != nil else { return "예정된 근무 없음" }
        let hours = computedHours()
        guard let hours else { return "근무 예정" }

        let rounded = (hours * 10).rounded() / 10
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(rounded))시간 근무 예정"
        }
        return "\(rounded)시간 근무 예정"
    }

    private func computedHours() -> Double? {
        if let start = model.shiftStart, let end = model.shiftEnd {
            let raw = end.timeIntervalSince(start) / 3600.0
            if raw > 0 {
                return raw
            }
        }

        if let planned = model.plannedHours, planned > 0 {
            return planned
        }

        return nil
    }
}
