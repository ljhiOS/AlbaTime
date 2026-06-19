//
//  JobSaveValidator.swift
//  AlbaTime
//
//  Created by 이준희 on 3/25/26.
//

import Foundation

struct JobSaveValidator {
    func validate(draft: JobDraft) throws {
        if draft.name.trimmingCharacters(in: .whitespaces).isEmpty {
            throw SaveJobError.emptyName
        }

        if draft.hourlyWage <= 0 {
            throw SaveJobError.invalidWage
        }
    }

    func validateFixedJob(
        orderedRegularSchedules: [RegularScheduleDraft],
        initialImportedSchedules: [ScheduleDraftItem]
    ) throws {
        if orderedRegularSchedules.isEmpty && initialImportedSchedules.isEmpty {
            throw SaveJobError.missingFixedSchedule
        }
    }
}
