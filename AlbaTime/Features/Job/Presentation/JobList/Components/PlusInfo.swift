//
//  PlusInfo.swift
//  AlbaTime
//
//  Created by 이준희 on 12/10/25.
//

import SwiftUI

struct PlusInfo: View {
    @Binding var memo: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("메모")
                .font(.title2)
                .padding()
            
            TextField("저장된 메모가 없습니다", text: $memo)
            .padding()
            .padding(.bottom)
            .padding(.bottom)
            .padding(.bottom)
            .background(Color.theme.surface)
            .cornerRadius(20)
            .padding()
            
        } //:VStack
        .background(Color.theme.field)
        .frame(maxWidth: .infinity)
        .cornerRadius(20)
    }
}

#Preview {
    PlusInfo(memo: .constant("사장님이 화, 목 오후 2시에 오십니다."))
}
