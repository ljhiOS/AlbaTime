//
//  NextShiftWidget.swift
//  AlbaTime
//
//  Created by 이준희 on 2/6/26.
//

import WidgetKit
import SwiftUI

struct NextShiftWidget: Widget {
    let kind: String = "NextShiftWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextShiftTimelineProvider()) { entry in
            WidgetView(entry: entry)
        }
        .configurationDisplayName("다음 근무 시작 시간")
        .description("다음 근무까지 남은 시간과 시작 시각을 표시합니다.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}
