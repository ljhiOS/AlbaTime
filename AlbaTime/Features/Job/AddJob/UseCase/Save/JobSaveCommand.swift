//
//  JobSaveCommand.swift
//  AlbaTime
//
//  Created by 이준희 on 5/2/26.
//

import Foundation

enum JobSaveCommand {
    case jobDraft(
        session: JobEditingSession,
        initialDefaultRestTime: Int?
    )
}
