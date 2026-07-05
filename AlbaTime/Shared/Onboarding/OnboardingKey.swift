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
    case payDashboardCard
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
             .payDashboardCard:
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
             .payDashboardCard:
            return 20

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
             .payDashboardCard:
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
             .payDashboardCard:
            return false
        }
    }
}
