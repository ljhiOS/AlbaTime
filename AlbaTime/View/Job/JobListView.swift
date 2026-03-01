//
//  JobListView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI
import SwiftData

struct JobListView: View {
    @Query(sort: \Workplace.createdAt, order: .reverse) var workplaces: [Workplace]
    @Environment(\.modelContext) private var modelContext
    
    @State private var showTypeSelection = false
    @State private var selectedWorkType: WorkType?
    @State private var selectedDetailJob: Workplace?
    @State private var selectedEditJob: Workplace?
    
    var pinnedJobs: [Workplace] {
        workplaces.filter { $0.isPinned }
    }
    
    var normalJobs: [Workplace] {
        workplaces.filter { !$0.isPinned }
    }
    
    var body: some View {
        
        VStack() {
            HStack {
                Text("근무지 목록")
                    .font(.largeTitle)
                    .bold()
                    .padding()
                Spacer()
            }
            
            if workplaces.isEmpty {
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
                            ForEach(pinnedJobs) { job in
                                WorkCard(job: job, onDelete: {
                                    deleteWorkCard(job)
                                }, onPin: {
                                    togglePin(job)
                                }, onShowDetail: {
                                    selectedDetailJob = job
                                }, onShowEdit: {
                                    selectedEditJob = job
                                })
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                            }
                        }
                    }
                    
                    Section {
                        ForEach(normalJobs) { job in
                            WorkCard(job: job, onDelete: {
                                deleteWorkCard(job)
                            }, onPin: {
                                togglePin(job)
                            }, onShowDetail: {
                                selectedDetailJob = job
                            }, onShowEdit: {
                                selectedEditJob = job
                            })
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
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
            AddJobView(stateName: "알바 등록", selectedType: type)
        }
        .navigationDestination(item: $selectedDetailJob) { job in
            DetailView(job: job)
        }
        .navigationDestination(item: $selectedEditJob) { job in
            AddJobView(job: job)
        }
        .onAppear {
            selectedWorkType = nil
            NextShiftSyncService.sync(workplaces: workplaces)
        }
    }
    
    // MARK: - Logic
    
    private func deleteWorkCard(_ workplace: Workplace) {
        NotificationManager.shared.removeNotifications(for: workplace)
        withAnimation {
            modelContext.delete(workplace)
        }
        
        do {
            try modelContext.save()
            let workplaces = try modelContext.fetch(FetchDescriptor<Workplace>())
            NextShiftSyncService.sync(workplaces: workplaces)
        } catch {
            print("삭제/동기화 실패: \(error)")
        }
    }
    
    private func togglePin(_ workplace: Workplace) {
        withAnimation {
            workplace.isPinned.toggle()
        }
    }
}

#Preview("데이터 없음") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Workplace.self,
        RegularSchedule.self,
        WorkTimePreset.self,
        configurations: config
    )

    return JobListView()
        .modelContainer(container)
}

#Preview("데이터있음") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Workplace.self,
        RegularSchedule.self,
        WorkTimePreset.self,
        configurations: config
    )

    let sample = Workplace(
        name: "자울 테스트",
        hourlyWage: 10320,
        defaultDays: "월/화/수/목/금",
        defaultStartTime: Date.makeTime(9, 0),
        defaultEndTime: Date.makeTime(18, 0),
        workType: .fixed
    )
    container.mainContext.insert(sample)

    return JobListView()
        .modelContainer(container)
}
