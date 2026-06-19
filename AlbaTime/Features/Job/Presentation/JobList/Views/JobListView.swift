//
//  JobListView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI

struct JobListView: View {
    let pinnedJobs: [JobListItemViewState]
    let normalJobs: [JobListItemViewState]
    let onAppear: () -> Void

    @StateObject private var jlvm: JobListViewModel
    @State private var showTypeSelection = false
    @State private var selectedWorkType: WorkType?
    @State private var selectedDetailState: JobDetailViewState?
    @State private var selectedEditSeed: JobEditingSeed?

    init(
        pinnedJobs: [JobListItemViewState],
        normalJobs: [JobListItemViewState],
        viewModel: @autoclosure @escaping () -> JobListViewModel,
        onAppear: @escaping () -> Void = {}
    ) {
        self.pinnedJobs = pinnedJobs
        self.normalJobs = normalJobs
        self.onAppear = onAppear
        _jlvm = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack {
            HStack {
                Text("근무지 목록")
                    .font(.largeTitle)
                    .bold()
                    .padding()
                Spacer()
            }

            if pinnedJobs.isEmpty && normalJobs.isEmpty {
                ContentUnavailableView(
                    "등록된 알바가 없어요...",
                    systemImage: "briefcase.fill",
                    description: Text("하단 버튼을 눌러\n새로운 알바를 추가해주세요!")
                )

                PlusButton {
                    showTypeSelection = true
                }
                .listRowSeparator(.hidden)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            } else {
                List {
                    if !pinnedJobs.isEmpty {
                        Section(header: Label("고정됨", systemImage: "pin.fill")) {
                            ForEach(pinnedJobs) { item in
                                card(item)
                            }
                        }
                    }

                    Section {
                        ForEach(normalJobs) { item in
                            card(item)
                        }
                    }

                    PlusButton {
                        showTypeSelection = true
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 16, trailing: 16))
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.theme.surface)
            }
        }
        .background(Color.theme.surface)
        .confirmationDialog("근무 형태를 선택해주세요", isPresented: $showTypeSelection, titleVisibility: .visible) {
            Button("요일 고정 알바") {
                selectedWorkType = .fixed
            }
            Button("자율/횟수 중심 알바") {
                selectedWorkType = .flexible
            }
            Button("취소", role: .cancel) {}
        }
        .navigationDestination(item: $selectedWorkType) { type in
            AddJobRoute(stateName: "알바 등록", selectedType: type)
        }
        .navigationDestination(item: $selectedDetailState) { state in
            DetailView(state: state) { memo in
                jlvm.updateMemo(workplaceID: state.id, memo: memo)
            }
        }
        .navigationDestination(item: $selectedEditSeed) { seed in
            AddJobRoute(editingSeed: seed)
        }
        .onAppear {
            selectedWorkType = nil
            onAppear()
        }
    }

    private func card(_ item: JobListItemViewState) -> some View {
        WorkCard(
            state: item.card,
            onDelete: {
                jlvm.delete(workplaceID: item.id)
            },
            onPin: {
                jlvm.togglePin(workplaceID: item.id)
            },
            onToggleAlarm: {
                if jlvm.toggleAlarm(workplaceID: item.id) {
                    Haptics.impact(.medium)
                }
            },
            onShowDetail: {
                selectedDetailState = item.detail
            },
            onShowEdit: {
                selectedEditSeed = item.editingSeed
            }
        )
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowBackground(Color.clear)
    }
}

#Preview("순수 JobListView") {
    let card = JobCardViewState(
        id: UUID(),
        name: "GS25 강남점",
        hourlyWage: 10320,
        isPinned: false,
        isAlarmEnabled: true,
        scheduleSummary: "월/수/금: 09:00 ~ 18:00"
    )
    let detail = JobDetailViewState(
        id: card.id,
        name: card.name,
        hourlyWage: card.hourlyWage,
        workType: .fixed,
        fixedDaysText: "월/수/금",
        defaultStartTime: Date.makeTime(9, 0),
        defaultEndTime: Date.makeTime(18, 0),
        targetWeeklyCount: 0,
        expectedDailyHours: 0,
        defaultRestTime: 60,
        memo: "사장님이 화, 목 오후 2시에 오십니다.",
        totalDays: 12,
        totalHours: 48,
        totalWage: 540000
    )
    let seed = JobEditingSeed(
        id: card.id,
        jobDraft: .makeNew(type: .fixed),
        scheduleImportDraft: .empty(),
        savedAIScheduleItems: [],
        initialDefaultRestTime: 60
    )

    return NavigationStack {
        JobListView(
            pinnedJobs: [],
            normalJobs: [
                JobListItemViewState(card: card, detail: detail, editingSeed: seed)
            ],
            viewModel: PreviewJobListViewModelFactory.make()
        )
    }
}

@MainActor
private enum PreviewJobListViewModelFactory {
    static func make() -> JobListViewModel {
        JobListViewModel(
            workplaceDeleting: PreviewJobListCommand(),
            alarmToggling: PreviewJobListCommand(),
            pinToggling: PreviewJobListCommand(),
            memoUpdating: PreviewJobListCommand()
        )
    }
}

@MainActor
private struct PreviewJobListCommand:
    WorkplaceDeleting,
    WorkplaceAlarmToggling,
    WorkplacePinToggling,
    WorkplaceMemoUpdating {
    func execute(workplaceID: UUID) throws { }
    func execute(workplaceID: UUID, memo: String) throws { }
}
