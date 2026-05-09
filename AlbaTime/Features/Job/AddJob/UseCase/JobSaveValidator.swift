//
//  JobSaveValidator.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation

struct JobSaveValidator {
    func validate(job: Workplace) throws {
        if job.name.trimmingCharacters(in: .whitespaces).isEmpty {
            throw SaveJobError.emptyName
        }

        if job.hourlyWage <= 0 {
            throw SaveJobError.invalidWage
        }
    }
    
    
    func validateFixedJob(job: Workplace) throws {
        if job.regularSchedules.isEmpty && job.workSchedules.isEmpty {
            throw SaveJobError.missingFixedSchedule
        }
    }
}
