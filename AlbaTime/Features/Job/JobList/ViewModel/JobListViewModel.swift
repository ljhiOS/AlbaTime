//
//  JobListViewModel.swift
//  AlbaTime
//
//  Created by 이준희 on 3/24/26.
//

import Foundation
import SwiftData

@MainActor
class JobListViewModel: ObservableObject {
    @Published var showDeleteError = false
    @Published var deleteErrorMessage = ""
    
    private let deleteWorkCard = DeleteWorkCard()
    
    func delete(_ workplace: Workplace, context: ModelContext) {
        do {
            try deleteWorkCard.execute(workplace: workplace, context: context)
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteError = true
        }
    }
}
