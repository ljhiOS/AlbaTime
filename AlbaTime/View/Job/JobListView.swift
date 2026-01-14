//
//  JobListView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI
import SwiftData

struct JobListView: View {
    // SwiftData 저장 된 데이터 사용
    @Query(sort: \Workplace.createdAt, order: .reverse) var workplaces: [Workplace]
    
    @Environment(\.modelContext) private var modelContext
    
    var pinnedJobs: [Workplace] {
        workplaces.filter { $0.isPinned }
    }
    
    var normalJobs: [Workplace] {
        workplaces.filter { !$0.isPinned }
    }
    
    var body: some View {
        
        VStack() {
            HStack {
                Text("알바목록")
                    .font(.largeTitle)
                    .bold()
                    .padding()
                
                Spacer()
            }
            if workplaces.isEmpty {
                
                ContentUnavailableView(
                    "등록된 알바가 없어요...",
                    systemImage: "briefcase.fill",
                    description: Text("새로운 알바를 추가해주세요!")
                )
                
                PlusButton()
                
            } else {
                List {
                    if !pinnedJobs.isEmpty {
                        Section {
                            ForEach(pinnedJobs) { job in
                                WorkCard(job: job, onDelete: {
                                    deleteWorkCard(job)
                                }, onPin: {
                                    togglePin(job) // 핀 기능 연결
                                })
                                .listRowSeparator(.hidden)
                            }
                        } header: {
                            Image(systemName: "pin") // 헤더 이름
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        }
                    }
                    
                    Section {
                        ForEach(normalJobs) { job in
                            WorkCard(job: job, onDelete: {
                                deleteWorkCard(job)
                            }, onPin: {
                                togglePin(job) // 핀 기능 연결
                            })
                            .listRowSeparator(.hidden)
                        }
                    }
                    
                    
                    PlusButton()
                        .listRowSeparator(.hidden)
                        
                }
                .listStyle(.plain)
            }
            
        } //:VStack
        
        Spacer()
        
        
    }
    
    private func deleteWorkCard(_ workplace: Workplace) {
        // 알림 삭제
        NotificationManager.shared.removeNotifications(for: workplace)
        
        withAnimation {
            modelContext.delete(workplace)
        }
    }
    
    private func togglePin(_ workplace: Workplace) {
        withAnimation {
            workplace.isPinned.toggle() // true <-> false 뒤집기
            // SwiftData는 클래스 객체의 속성만 바꾸면 자동 저장됩니다.
        }
    }
}

#Preview {
    // 프리뷰 위한 예시 컨테이너
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workplace.self, configurations: config)
    JobListView()
        .modelContainer(container)
}
