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
    
    var pinnedJobs: [Workplace] {
        workplaces.filter { $0.isPinned }
    }
    
    var normalJobs: [Workplace] {
        workplaces.filter { !$0.isPinned }
    }
    
    var body: some View {
        VStack() {
            HStack {
                Text("알바 목록")
                    .font(.largeTitle)
                    .bold()
                    .padding()
                Spacer()
            }
            
            if workplaces.isEmpty {
                ContentUnavailableView(
                    "등록된 알바가 없어요...",
                    systemImage: "briefcase.fill",
                    description: Text("우측 하단 버튼을 눌러\n새로운 알바를 추가해주세요!")
                )
                
                // 빈 화면일 때 추가 버튼
                PlusButton {
                    showTypeSelection = true
                }
                .listRowSeparator(.hidden)
                
            } else {
                List {
                    // 1. 고정된 알바
                    if !pinnedJobs.isEmpty {
                        Section(header: Label("고정됨", systemImage: "pin.fill")) {
                            ForEach(pinnedJobs) { job in
                                WorkCard(job: job, onDelete: {
                                    deleteWorkCard(job)
                                }, onPin: {
                                    togglePin(job)
                                })
                                .listRowSeparator(.hidden)
                            }
                        }
                    }
                    
                    // 2. 일반 알바
                    Section {
                        ForEach(normalJobs) { job in
                            WorkCard(job: job, onDelete: {
                                deleteWorkCard(job)
                            }, onPin: {
                                togglePin(job)
                            })
                            .listRowSeparator(.hidden)
                        }
                    }
                    
                    // 리스트 하단 추가 버튼
                    PlusButton {
                        showTypeSelection = true
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
            
        } //:VStack
        .confirmationDialog("근무 형태를 선택해주세요", isPresented: $showTypeSelection, titleVisibility: .visible) {
            Button("요일 고정 알바") {
                selectedWorkType = .fixed
            }
            Button("자율/횟수 중심 알바") {
                selectedWorkType = .flexible
            }
            Button("취소", role: .cancel) {}
        }
        .sheet(item: $selectedWorkType) { type in
            AddJobView(stateName: "알바 등록", selectedType: type)
        }
    }
    
    // MARK: - Logic
    
    private func deleteWorkCard(_ workplace: Workplace) {
        NotificationManager.shared.removeNotifications(for: workplace)
        withAnimation {
            modelContext.delete(workplace)
        }
    }
    
    private func togglePin(_ workplace: Workplace) {
        withAnimation {
            workplace.isPinned.toggle()
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workplace.self, RegularSchedule.self, WorkTimePreset.self, configurations: config)
    JobListView()
        .modelContainer(container)
}
