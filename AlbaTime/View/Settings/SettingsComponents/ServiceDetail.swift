//
//  ServiceDetail.swift
//  AlbaTime
//
//  Created by 이준희 on 12/29/25.
//

import SwiftUI

struct ServiceDetail: View {
    
    
    @State var isShowHelp: Bool = false
    
    var body: some View {
        
            
            VStack(alignment: .leading) {
                Text("지원")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.top)
                    
                VStack() {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(Color.theme.primary)
                        
                        Text("도움말")
                        
                        Spacer()
                        
                        Button {
                            isShowHelp = true
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .sheet(isPresented: $isShowHelp) {
                            HelpView()
                        }
                    }
                    .padding(.vertical, 3)
                    
                    Divider()
                    
                    
                        
                        
                    NavigationLink(destination: AppInfo()) {
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundStyle(Color.theme.primary)
                            
                            Text("앱 정보")
                                .foregroundStyle(Color.theme.textPrimary)
                            
                            Spacer()
                            
                            
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color.theme.primary)
                        }
                        .padding(.vertical, 3)
                    }.buttonStyle(.plain)
                    
                    
                    
                    Divider()
                    
                    NavigationLink(destination: PersonalInfo()) {
                        
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundStyle(Color.theme.primary)
                            
                            Text("개인정보처리방침")
                                .foregroundStyle(Color.theme.textPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color.theme.primary)
                            
                        }
                        .padding(.vertical, 3)
                    }
                    .buttonStyle(.plain)
                    
                } //:HStack
                .padding()
                .background(Color.theme.muted)
                .cornerRadius(20)
            }
       
    }
}

#Preview {
    NavigationStack {
        
        ServiceDetail()
    }
}
