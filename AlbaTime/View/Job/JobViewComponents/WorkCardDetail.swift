//
//  WorkCardDetail.swift
//  AlbaTime
//
//  Created by 이준희 on 12/9/25.
//

import SwiftUI

struct WorkCardDetail: View {
    let job: Workplace
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                
                Circle()
                    .frame(width: 15, height: 15)
                    .foregroundStyle(.white)
                
                Text("\(job.name)")
                    .font(.title2)
                    .foregroundStyle(.white)
                
                Spacer()
                
            }.padding(.top)
             .padding(.leading)
            
            VStack(alignment: .leading) {
                Text("시급")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    
                
                Text("\(job.hourlyWage)원")
                    .foregroundStyle(.yellow)
                    .font(.title)
            }.padding(.horizontal)
            
            Divider()
                .frame(height: 1)
                .background(Color.white)
                .padding(.horizontal)
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("기본 근무 시간")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    
                    Text("\(job.defaultDays)")
                        .foregroundStyle(.white)
                        .bold(true)
                    
                    Text("\(job.defaultStartTime.format("HH:mm")) - \(job.defaultEndTime.format("HH:mm"))")
                        .foregroundStyle(.white)
                        .bold(true)
                        
                 
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("이번 달")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    
                    Text("48시간")
                        .foregroundStyle(.white)
                        .font(.system(size: 20))
                        .bold(true)
                    
                    Text("휴게시간")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    
                    Text("1시간")
                        .foregroundStyle(.white)
                        .font(.system(size: 20))
                        .bold(true)
                }
                
                Spacer()
            }.padding()
        }.background(Color.theme.primary)
            .frame(maxWidth: .infinity)
            .cornerRadius(20)
            .padding(.horizontal, 30)
    }
}

#Preview {
    WorkCardDetail(job: Workplace(
        name: "GS25 강남점",
        hourlyWage: 10030,
        defaultDays: "월,수,금",
        defaultStartTime: Date.makeTime(9, 0),
        defaultEndTime: Date.makeTime(18, 0),
//        allTimes: "48시간"
    ))
}
