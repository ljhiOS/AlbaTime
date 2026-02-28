//
//  PlusInfo.swift
//  AlbaTime
//
//  Created by 이준희 on 12/10/25.
//

import SwiftUI
import SwiftData

struct PlusInfo: View {
    
    @Bindable var job: Workplace
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("메모")
                .font(.title2)
                .padding()
            
            TextField("저장된 메모가 없습니다", text: Binding(get: {
                job.defaultMemo ?? ""
            }, set: {
                job.defaultMemo = $0
            })
            )
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
    // 프리뷰 용 코드 ai 복붙
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Workplace.self, configurations: config)
        
        // 2. 샘플 데이터 생성 (Workplace의 init 요구사항인 이름, 시급 필수 입력)
        let sampleJob = Workplace(
            name: "GS25 강남점",
            hourlyWage: 9860,
            defaultDays: "월, 수, 금",
            defaultStartTime: Date.makeTime(9, 0),
            defaultEndTime: Date.makeTime(18, 0),
            defaultMemo: "사장님이 화, 목 오후 2시에 오십니다."// 테스트용 메모
        )
        
        // 3. 데이터를 컨테이너에 등록 (SwiftData가 인식하도록)
        container.mainContext.insert(sampleJob)
        
        // 4. 뷰에 데이터 전달 및 컨테이너 주입
        return PlusInfo(job: sampleJob)
            .modelContainer(container)
}
