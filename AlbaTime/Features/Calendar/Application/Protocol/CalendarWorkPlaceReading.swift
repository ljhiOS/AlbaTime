//
//  CalendarWorkPlaceReading.swift
//  AlbaTime
//
//  Created by 이준희 on 7/4/26.
//

import Foundation

@MainActor
protocol CalendarWorkPlacesLoading {
    func execute() throws -> [WorkPlace]
}

@MainActor
protocol CalendarWorkPlaceReading {
    func fetchWorkPlaces() throws -> [WorkPlace]
}
