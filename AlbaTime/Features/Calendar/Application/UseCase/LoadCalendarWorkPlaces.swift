//
//  LoadCalendarWorkPlaces.swift
//  AlbaTime
//
//  Created by 이준희 on 7/4/26.
//

import Foundation

@MainActor
struct LoadCalendarWorkPlaces: CalendarWorkPlacesLoading {
    private let reader: any CalendarWorkPlaceReading
    
    init(reader: any CalendarWorkPlaceReading) {
        self.reader = reader
    }
    
    func execute() throws -> [WorkPlace] {
        try reader.fetchWorkPlaces()
    }
}
