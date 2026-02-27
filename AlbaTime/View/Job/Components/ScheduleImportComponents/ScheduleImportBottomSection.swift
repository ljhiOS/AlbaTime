import SwiftUI
import UIKit

struct ScheduleImportBottomSection: View {
    @ObservedObject var sivm: ScheduleImportViewModel
    let selectedWeekStart: Date?
    let onSaved: () -> Void
    let onManualInput: () -> Void

    var body: some View {
        Group {
            if sivm.selectedImage != nil {
                ScheduleImportBottomButtons(
                    sivm: sivm,
                    selectedWeekStart: selectedWeekStart,
                    onSaved: onSaved,
                    onManualInput: onManualInput
                )
            }
        }
    }
}

#Preview("Bottom Section") {
    struct PreviewWrapper: View {
        @StateObject private var vm = ScheduleImportViewModel()

        var body: some View {
            VStack {
                Spacer()
                ScheduleImportBottomSection(
                    sivm: vm,
                    selectedWeekStart: nil,
                    onSaved: {},
                    onManualInput: {}
                )
            }
            .onAppear {
                vm.selectedImage = UIImage()
                vm.parsedSchedules = [
                    ParsedSchedule(
                        date: Date(),
                        startTime: Date(),
                        endTime: Date(),
                        scheduleName: "테스트"
                    )
                ]
            }
        }
    }

    return PreviewWrapper()
}
