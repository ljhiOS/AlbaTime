//
//  SharedShift.swift
//  AlbaTime
//
//  Created by 이준희 on 3/22/26.
//

import Foundation

struct SharedShift: Codable {
    let workplaceName: String
    let startTimestamp: TimeInterval
    let endTimestamp: TimeInterval
    let plannedHours: Double?
}
