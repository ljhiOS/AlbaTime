//
//  Untitled.swift
//  AlbaTime
//
//  Created by 이준희 on 7/3/26.
//
import Foundation

struct JobCardViewState: Identifiable, Hashable {
    let id: UUID
    let name: String
    let hourlyWage: Int
    let isPinned: Bool
    let isAlarmEnabled: Bool
    let scheduleSummary: String
}
