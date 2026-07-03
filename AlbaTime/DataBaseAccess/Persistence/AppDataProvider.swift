//
//  DataProvider.swift
//  AlbaTime
//
//  Created by 이준희 on 5/2/26.
//

import Foundation
import SwiftData

// TODO: Job 설계 구조에 맞춰 전체 프로젝트 설계 변경 완료시 삭제

@MainActor
final class AppDataProvider {
    private let container: ModelContainer
    private let context: ModelContext
    
    init() {
        self.container = try! ModelContainer(
            for: WorkPlace.self,
            MonthlyRecord.self,
            RegularSchedule.self,
            WorkSchedule.self,
            WorkTimePreset.self
        )
        self.context = container.mainContext
    }
    
    func fetchWorkPlaces() throws -> [WorkPlace] {
        let descriptor = FetchDescriptor<WorkPlace> (
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
}
