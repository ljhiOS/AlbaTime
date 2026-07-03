import Foundation

enum ScheduleEditState: Equatable {
    case newWorkPlaceInitialSchedules
    case existingWorkPlaceAIImport
    case existingSavedAIEdit
}

struct ScheduleEditDraft {
    var state: ScheduleEditState
    var targetWeekStart: Date?
    var items: [ScheduleEditItem]
}

extension ScheduleEditDraft {
    static func empty(
        state: ScheduleEditState,
        targetWeekStart: Date? = nil
    ) -> ScheduleEditDraft {
        ScheduleEditDraft(
            state: state,
            targetWeekStart: targetWeekStart,
            items: []
        )
    }
}
