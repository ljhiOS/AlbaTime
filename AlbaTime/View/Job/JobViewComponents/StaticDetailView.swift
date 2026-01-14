//
//  StaticDetailView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/10/25.
//

import SwiftUI

struct StaticDetailView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("이번 달 통계")
                .font(.title2)
                .padding()
                
            
            HStack {
                Spacer()
                StaticDetailComponents(icon: "calendar", title: "근무일수", caption: "12일")
                Spacer()
                StaticDetailComponents(icon: "calendar", title: "근무일수", caption: "12일")
                Spacer()
                StaticDetailComponents(icon: "calendar", title: "근무일수", caption: "12일")
                Spacer()
            } //:HStack
            .padding()
            .frame(maxWidth: .infinity)
        } //:VStack
        .background(Color.gray.opacity(0.1))
        .frame(maxWidth: .infinity)
        .cornerRadius(20)
        .padding(.horizontal,30)
    }
}

struct StaticDetailComponents: View {
    let icon: String
    let title: String
    let caption: String
    var body: some View {
        VStack {
            Image(systemName: icon)
                .resizable()
                .foregroundStyle(.blue)
                .frame(width: 20, height: 20)
                .padding(10)
                .background(
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                )
            
            Text(title)
                .font(.caption)
            Text(caption)
        
        }.padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)
    }
}

#Preview {
    StaticDetailView()
}
