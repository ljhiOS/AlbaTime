//
//  BreakTime.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation

struct ApplyBreakTime {
    func breakTime(job: WorkPlace, initialDefaultRestTime: Int?) {
        let updatedBreakTime = max(0, job.defaultRestTime ?? 0)
        
        if job.defaultRestTime == nil {
            for schedule in job.regularSchedules {
                schedule.breakTime = 0
            }
            for schedule in job.workSchedules {
                schedule.breakTime = 0
            }
        } else if initialDefaultRestTime != job.defaultRestTime {
            let previousBreakTime = max(0, initialDefaultRestTime ?? 0)
            
            for schedule in job.regularSchedules
            where schedule.breakTime == 0 || schedule.breakTime == previousBreakTime {
                schedule.breakTime = updatedBreakTime
            }
            
            for schedule in job.workSchedules
            where schedule.breakTime == 0 || schedule.breakTime == previousBreakTime {
                schedule.breakTime = updatedBreakTime
            }
        } else {
            for schedule in job.regularSchedules where schedule.breakTime == 0 {
                schedule.breakTime = updatedBreakTime
            }
            
            for schedule in job.workSchedules where schedule.breakTime == 0 {
                schedule.breakTime = updatedBreakTime
            }
        }
    }
    
}
