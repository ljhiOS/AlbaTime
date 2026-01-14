//
//  SwiftUIView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/9/25.
//

// 상세 보기 뷰

import SwiftUI

struct DetailView: View {
    let job: Workplace
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                HStack {
                    Text("상세보기")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.black)
                            .font(.title)
                    }
                } //:HStack
                .padding()
                
                WorkCardDetail(job: job)
                
                StaticDetailView()
                
                PlusInfo(job: job)
                
            } //:VStack
        } //:ScrollViewEnd
    }
}

#Preview {
    DetailView(job: Workplace(
        name: "GS25 강남점",
        hourlyWage: 10030,
        defaultDays: "월/수/금",
        defaultStartTime: Date.makeTime(9, 0),
        defaultEndTime: Date.makeTime(18, 0)
//        allTimes: "48시간"
    ))
}
