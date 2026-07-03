//
//  BreakTime.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation

struct ApplyBreakTime {
    func breakTime(workPlace: WorkPlace, initialDefaultRestTime: Int?) {
        let updatedBreakTime = max(0, workPlace.defaultRestTime ?? 0)
        
        if workPlace.defaultRestTime == nil {
            for schedule in workPlace.regularSchedules {
                schedule.breakTime = 0
            }
            for schedule in workPlace.workSchedules {
                schedule.breakTime = 0
            }
        } else if initialDefaultRestTime != workPlace.defaultRestTime {
            let previousBreakTime = max(0, initialDefaultRestTime ?? 0)
            
            for schedule in workPlace.regularSchedules
            where schedule.breakTime == 0 || schedule.breakTime == previousBreakTime {
                schedule.breakTime = updatedBreakTime
            }
            
            for schedule in workPlace.workSchedules
            where schedule.breakTime == 0 || schedule.breakTime == previousBreakTime {
                schedule.breakTime = updatedBreakTime
            }
        } else {
            for schedule in workPlace.regularSchedules where schedule.breakTime == 0 {
                schedule.breakTime = updatedBreakTime
            }
            
            for schedule in workPlace.workSchedules where schedule.breakTime == 0 {
                schedule.breakTime = updatedBreakTime
            }
        }
    }
    
}
