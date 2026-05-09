//
//  SaveScheduleCommand.swift
//  AlbaTime
//
//  Created by 이준희 on 5/3/26.
//

import Foundation

enum SaveScheduleCommand {
    case editDraft(
        job: Workplace?,
        draft: ScheduleEditDraft
    )
}
