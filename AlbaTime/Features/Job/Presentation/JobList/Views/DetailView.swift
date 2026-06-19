//
//  DetailView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/9/25.
//

// 상세 보기 뷰

import SwiftUI

struct DetailView: View {
    let state: JobDetailViewState
    var onMemoChange: (String) -> Void = { _ in }

    @State private var memo: String

    init(
        state: JobDetailViewState,
        onMemoChange: @escaping (String) -> Void = { _ in }
    ) {
        self.state = state
        self.onMemoChange = onMemoChange
        _memo = State(initialValue: state.memo)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                
                WorkCardDetail(state: state)
                    .padding(.horizontal, 30)
                
                StaticDetailView(
                    totalDays: state.totalDays,
                    totalHours: state.totalHours,
                    totalWage: state.totalWage
                )
                .padding(.horizontal, 30)
                
                PlusInfo(memo: $memo)
                    .padding(.horizontal, 30)
                
            } //:VStack
        } //:ScrollViewEnd
        .toolbar(.hidden, for: .tabBar)
        .background(Color.theme.surface)
        .navigationTitle("상세보기")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: memo) { _, newValue in
            onMemoChange(newValue)
        }
    }
}

#Preview {
    DetailView(state: JobDetailViewState(
        id: UUID(),
        name: "GS25 강남점",
        hourlyWage: 10320,
        workType: .fixed,
        fixedDaysText: "월/수/금",
        defaultStartTime: Date.makeTime(9, 0),
        defaultEndTime: Date.makeTime(18, 0),
        targetWeeklyCount: 0,
        expectedDailyHours: 0,
        defaultRestTime: nil,
        memo: "",
        totalDays: 12,
        totalHours: 48,
        totalWage: 540000
    ))
}
