//
//  ImageAnalyzing.swift
//  AlbaTime
//
//  Created by 이준희 on 9/13/26.
//

import Foundation
import UIKit

@available(iOS 26.0, *)
protocol ImageAnalyzing {
    func analyze(name: String?, year: Int, image: UIImage) async throws -> AIScheduleExtraction
}
