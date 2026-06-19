//
//  JobSaving.swift
//  AlbaTime
//
//  Created by Codex on 5/18/26.
//

import Foundation

@MainActor
protocol JobSaving {
    func execute(_ command: JobSaveCommand) throws
}
