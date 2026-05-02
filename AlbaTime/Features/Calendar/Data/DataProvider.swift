//
//  DataProvider.swift
//  AlbaTime
//
//  Created by 이준희 on 5/2/26.
//

import Foundation
import SwiftData

@MainActor
final class DataProvider {
    private let container: ModelContainer
    private let context: ModelContext
    
    init() {
        self.container = try! ModelContainer(
            for: Workplace.self,
            MonthlyRecord.self,
            RegularSchedule.self,
            WorkSchedule.self,
            WorkTimePreset.self
        )
        self.context = container.mainContext
    }
    
    func fetch() throws -> [Workplace] {
        let descriptor = FetchDescriptor<Workplace> (
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
}
