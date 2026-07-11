//
//  OnboardingKey.swift
//  AlbaTime
//
//  Created by 이준희 on 7/5/26.
//

import CoreGraphics

enum OnboardingKey: String, CaseIterable {
    case workPlaceListAddButton
    case workPlaceListDetailButton
    case workPlaceListEditButton
    case addWorkPlaceAICondition
    case scheduleImportDateBase
    case scheduleImportNameInput
    case scheduleImportPresetInput
    case calendarMonthPickerButton
    case calendarSwipeArea
    case calendarScheduleEdit
    case payDashboardBreakdown
}

extension OnboardingKey {
    var spotlightPadding: CGFloat {
        switch self {
        case .workPlaceListAddButton,
             .workPlaceListDetailButton,
             .workPlaceListEditButton,
             .addWorkPlaceAICondition,
             .scheduleImportDateBase,
             .scheduleImportNameInput,
             .scheduleImportPresetInput,
             .calendarMonthPickerButton,
             .calendarSwipeArea,
             .calendarScheduleEdit,
             .payDashboardBreakdown:
            return 0
        }
    }

    var spotlightCornerRadius: CGFloat {
        switch self {
        case .workPlaceListDetailButton,
             .workPlaceListEditButton:
            return 8

        case .workPlaceListAddButton,
             .calendarMonthPickerButton,
             .addWorkPlaceAICondition,
             .payDashboardBreakdown:
            return 20

        case .calendarScheduleEdit:
            return 12

        case .scheduleImportDateBase,
             .scheduleImportNameInput,
             .scheduleImportPresetInput,
             .calendarSwipeArea:
            return 14
        }
    }

    var keepsBubbleBelowTarget: Bool {
        switch self {
        case .addWorkPlaceAICondition,
             .scheduleImportDateBase,
             .scheduleImportNameInput,
             .scheduleImportPresetInput,
             .calendarMonthPickerButton:
            return true

        case .workPlaceListAddButton,
             .workPlaceListDetailButton,
             .workPlaceListEditButton,
             .calendarSwipeArea,
             .calendarScheduleEdit,
             .payDashboardBreakdown:
            return false
        }
    }

    var showsSwipeCue: Bool {
        switch self {
        case .calendarSwipeArea:
            return true

        case .workPlaceListAddButton,
             .workPlaceListDetailButton,
             .workPlaceListEditButton,
             .addWorkPlaceAICondition,
             .scheduleImportDateBase,
             .scheduleImportNameInput,
             .scheduleImportPresetInput,
             .calendarMonthPickerButton,
             .calendarScheduleEdit,
             .payDashboardBreakdown:
            return false
        }
    }
}
