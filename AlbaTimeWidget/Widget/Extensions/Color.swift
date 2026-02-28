//
//  Color.swift
//  AlbaTime
//
//  Created by 이준희 on 2/9/26.
//

import SwiftUI
import UIKit

extension Color {
    static let theme = Theme()

    static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        })
    }
}

struct Theme {
    let primary = Color(hex: "0066FF") // 브랜드 블루
    let accent = Color(hex: "FFB020")  // 급여 강조 (노랑)
    let textPrimary = Color.adaptive(light: .black, dark: .label)
    let textSecondary = Color.adaptive(light: .gray, dark: .secondaryLabel)
    let surface = Color.adaptive(
        light: .white,
        dark: UIColor(red: 0x12 / 255.0, green: 0x13 / 255.0, blue: 0x18 / 255.0, alpha: 1.0) // #121318
    )
    let field = Color.adaptive(
        light: UIColor.gray.withAlphaComponent(0.08),
        dark: UIColor(red: 0x1A / 255.0, green: 0x1B / 255.0, blue: 0x20 / 255.0, alpha: 1.0)
    )
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
