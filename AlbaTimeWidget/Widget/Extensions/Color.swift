//
//  Color.swift
//  AlbaTime
//
//  Created by 이준희 on 2/9/26.
//

import SwiftUI

extension Color {
    static let theme = Theme()
}

struct Theme {
    let primary = Color(hex: "0066FF") // 브랜드 블루
    let accent = Color(hex: "FFB020")  // 급여 강조 (노랑)
    let textPrimary = Color.black
    let textSecondary = Color.gray
}

// Hex 코드 지원용 확장
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >>  8) & 0xFF) / 255.0
        let b = Double((rgb >>  0) & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
