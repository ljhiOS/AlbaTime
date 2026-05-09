//
//  WorkType.swift
//  AlbaTime
//
//  Created by 이준희 on 3/22/26.
//

enum WorkType: String, Codable, CaseIterable, Identifiable {
    case fixed = "요일 고정"
    case flexible = "횟수/시간 중심"
    var id: Self { self }
}
