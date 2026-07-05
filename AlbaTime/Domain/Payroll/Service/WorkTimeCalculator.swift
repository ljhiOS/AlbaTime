//
//  WorkTimeCalculator.swift
//  AlbaTime
//
//  Created by 이준희 on 7/5/26.
//

import Foundation

struct WorkTimeCalculator {
    static func calculate(start: Date, end: Date, restTime: Int) -> (total: Double, night: Double) {
        let calendar = Calendar.current
        let startH = calendar.component(.hour, from: start)
        let startM = calendar.component(.minute, from: start)
        let endH = calendar.component(.hour, from: end)
        let endM = calendar.component(.minute, from: end)
        
        let startMins = startH * 60 + startM
        var endMins = endH * 60 + endM
        if endMins < startMins { endMins += 1440 }
        
        let rawDiffMins = Double(endMins - startMins)
        let netDiffMins = max(0, rawDiffMins - Double(restTime))
        let totalHours = netDiffMins / 60.0
        
        var nightMinsCount = 0
        for t in startMins..<endMins {
            let normalized = t % 1440
            if normalized < 360 || normalized >= 1320 {
                nightMinsCount += 1
            }
        }
        
        let ratio = rawDiffMins > 0 ? netDiffMins / rawDiffMins : 1.0
        let nightHours = (Double(nightMinsCount) * ratio) / 60.0
        
        return (totalHours, nightHours)
    }
}
