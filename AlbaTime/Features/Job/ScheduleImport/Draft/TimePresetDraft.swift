//
//  TimePresetDraft.swift
//  AlbaTime
//
//  Created by 이준희 on 3/26/26.
//

import Foundation

struct TimePresetDraft: Identifiable {
    let id: UUID
    var label: String
    var startTime: Date
    var endTime: Date
}
