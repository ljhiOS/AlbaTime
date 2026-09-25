//
//  ImageAnalyzing.swift
//  AlbaTime
//
//  Created by 이준희 on 9/13/26.
//

import Foundation
import UIKit

@available(iOS 27.0, *)
struct AgentSchedulePreset {
    let label: String
    let startTime: String
    let endTime: String
}

@MainActor
@available(iOS 27.0, *)
protocol ImageAnalyzing {
    func analyze(
        name: String?,
        referenceDate: Date,
        presets: [AgentSchedulePreset],
        image: UIImage
    ) async throws -> AIScheduleExtraction
}
