//
//  ParsedSchedule.swift
//  AlbaTime
//
//  Created by 이준희 on 1/18/26.
//
import Foundation

// OCR 결과 앱 데이터로 변환한 최종 결과물
struct ParsedSchedule: Identifiable {
    let id = UUID()
    var date: Date
    var startTime: Date
    var endTime: Date
    var scheduleName: String?
}
