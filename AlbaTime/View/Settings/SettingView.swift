//
//  SettingView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/8/25.
//

import SwiftUI

struct SettingView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("설정")
                    .font(.largeTitle)
                    .bold()
                    .padding()
                
                Spacer()
            }
            
            
            
            AccountDetail()
                .padding(.horizontal)
            
            ServiceDetail()
                .padding(.horizontal)
            Spacer()
            
            VStack(alignment: .center) {
                
                Text("AlbaTime")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("알바생 맞춤 출퇴근 스케줄러 & 급여계산기")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Copyright © 2026 AlbaTime.\nAll rights reserved.")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
            }.padding()
            
        }
    }
}

#Preview {
    NavigationStack{
        SettingView()
    }
}
