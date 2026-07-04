//
//  WorkPlaceListView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI

struct WorkPlaceListView: View {
    let pinnedWorkPlaces: [WorkPlaceListItemViewState]
    let normalWorkPlaces: [WorkPlaceListItemViewState]
    let onAppear: () -> Void

    @StateObject private var jlvm: WorkPlaceListViewModel
    @State private var showTypeSelection = false
    @State private var selectedWorkType: WorkType?
    @State private var selectedDetailState: WorkPlaceDetailViewState?
    @State private var selectedEditSeed: WorkPlaceEditingSeed?

    init(
        pinnedWorkPlaces: [WorkPlaceListItemViewState],
        normalWorkPlaces: [WorkPlaceListItemViewState],
        viewModel: @autoclosure @escaping () -> WorkPlaceListViewModel,
        onAppear: @escaping () -> Void = {}
    ) {
        self.pinnedWorkPlaces = pinnedWorkPlaces
        self.normalWorkPlaces = normalWorkPlaces
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

            if pinnedWorkPlaces.isEmpty && normalWorkPlaces.isEmpty {
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
                    if !pinnedWorkPlaces.isEmpty {
                        Section(header: Label("고정됨", systemImage: "pin.fill")) {
                            ForEach(pinnedWorkPlaces) { item in
                                makeCard(item)
                            }
                        }
                    }

                    Section {
                        ForEach(normalWorkPlaces) { item in
                            makeCard(item)
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
            Button("요일 비고정 알바") {
                selectedWorkType = .flexible
            }
            Button("취소", role: .cancel) {}
        }
        .navigationDestination(item: $selectedWorkType) { selectedType in
            AddWorkPlaceRoute(stateName: "알바 등록", selectedType: selectedType)
        }
        .navigationDestination(item: $selectedDetailState) { state in
            DetailView(state: state) { memo in
                jlvm.updateMemo(workPlaceID: state.id, memo: memo)
            }
        }
        .navigationDestination(item: $selectedEditSeed) { seed in
            AddWorkPlaceRoute(editingSeed: seed)
        }
        .onAppear {
            selectedWorkType = nil
            onAppear()
        }
    }

    private func makeCard(_ item: WorkPlaceListItemViewState) -> some View {
        WorkCard(
            state: item.card,
            onDelete: {
                jlvm.delete(workPlaceID: item.id)
            },
            onPin: {
                jlvm.togglePin(workPlaceID: item.id)
            },
            onToggleAlarm: {
                if jlvm.toggleAlarm(workPlaceID: item.id) {
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


#Preview("순수 WorkPlaceListView") {
    let card = WorkPlaceCardViewState(
        id: UUID(),
        name: "GS25 강남점",
        hourlyWage: 10320,
        isPinned: false,
        isAlarmEnabled: true,
        scheduleSummary: "월/수/금: 09:00 ~ 18:00"
    )
    let detail = WorkPlaceDetailViewState(
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
    let seed = WorkPlaceEditingSeed(
        id: card.id,
        workPlaceDraft: .makeNew(type: .fixed),
        scheduleImportDraft: .empty(),
        savedAIScheduleItems: [],
        initialDefaultRestTime: 60
    )

    return NavigationStack {
        WorkPlaceListView(
            pinnedWorkPlaces: [],
            normalWorkPlaces: [
                WorkPlaceListItemViewState(card: card, detail: detail, editingSeed: seed)
            ],
            viewModel: PreviewWorkPlaceListViewModelFactory.make()
        )
    }
}

@MainActor
private enum PreviewWorkPlaceListViewModelFactory {
    static func make() -> WorkPlaceListViewModel {
        WorkPlaceListViewModel(
            workPlaceDeleting: PreviewWorkPlaceListCommand(),
            alarmToggling: PreviewWorkPlaceListCommand(),
            pinToggling: PreviewWorkPlaceListCommand(),
            memoUpdating: PreviewWorkPlaceListCommand()
        )
    }
}

@MainActor
private struct PreviewWorkPlaceListCommand:
    WorkPlaceDeleting,
    WorkPlaceAlarmToggling,
    WorkPlacePinToggling,
    WorkPlaceMemoUpdating {
    func execute(workPlaceID: UUID) throws { }
    func execute(workPlaceID: UUID, memo: String) throws { }
}
