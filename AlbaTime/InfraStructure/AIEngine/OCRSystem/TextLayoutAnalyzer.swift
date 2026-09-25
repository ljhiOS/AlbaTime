//
//  TextLayoutAnalyzer.swift
//  AlbaTime
//
//  Created by 이준희 on 1/17/26.
//

import Foundation
import CoreGraphics

// 해당하는 텍스트가 행 안에서 어느열에 있는지를 표현
struct TextElement: Sendable {
    let text: String // OCR로 인식된 문자열
    let midX: CGFloat // 해당 텍스트 박스의 가로 중심값
    var boundingBox: CGRect? = nil
    var confidence: Float = 1
    var alternatives: [OCRTextAlternative] = []
}

// OCR 텍스트를 파서에서 다루기 쉬운 행 단위로 묶은 구조
// 파서가 줄 단위로 해석할 수 있는 기본 단위
struct TextRow: Sendable {
    let elements: [TextElement]
    
    var fullText: String {
        elements.map { $0.text }.joined(separator: " ")
    }
}

// 역할: OCR 결과(RawTextBox)를 행 기반 텍스트로 변환
// 파서가 위치 해석하기 쉬운 구조를 만들어주는 전처리계층
final class TextLayoutAnalyzer {
    
    // 위치 기반 OCR 결과를 같은 행(Row) 기준으로 그룹화한다.
    static func groupByRow(_ boxes: [RawTextBox]) -> [TextRow] {
        guard !boxes.isEmpty else { return [] }
        
        // 노이즈 제거
        let validBoxes = boxes.filter {
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && $0.boundingBox.width > 0 && $0.boundingBox.height > 0
        }
        
        // Vision 좌표계: y가 클수록 위 // y축 기준 정렬
        let sortedByY = validBoxes.sorted {
            if $0.boundingBox.midY != $1.boundingBox.midY {
                return $0.boundingBox.midY > $1.boundingBox.midY
            }
            return $0.boundingBox.minX < $1.boundingBox.minX
        }
        
        var rows: [[RawTextBox]] = []
        
        for box in sortedByY {
            let matchingRows = rows.indices.filter { index in
                rows[index].contains { isSameLine($0.boundingBox, box.boundingBox) }
            }
            if let index = matchingRows.min(by: {
                abs(centerY(rows[$0]) - box.boundingBox.midY) < abs(centerY(rows[$1]) - box.boundingBox.midY)
            }) {
                rows[index].append(box)
            } else {
                rows.append([box])
            }
        }
        
        return rows.map { rowBoxes in
            let sortedX = rowBoxes.sorted {
                $0.boundingBox.minX < $1.boundingBox.minX
            }
            return TextRow(
                elements: sortedX.map {
                    TextElement(text: $0.text, midX: $0.boundingBox.midX,
                                boundingBox: $0.boundingBox, confidence: $0.confidence,
                                alternatives: $0.alternatives)
                }
            )
        }
    }
    
    private static func isSameLine(_ a: CGRect, _ b: CGRect) -> Bool {
        // 큰 박스 하나가 이웃한 두 사람의 행을 연결하지 않도록
        // 작은 박스의 높이를 기준으로 두 조건을 모두 확인한다.
        let yCenterDiff = abs(a.midY - b.midY)
        let smallerHeight = min(a.height, b.height)
        let largerHeight = max(a.height, b.height)
        let overlap = min(a.maxY, b.maxY) - max(a.minY, b.minY)
        guard smallerHeight > 0 else { return false }

        // A tall observation can bridge two adjacent people. Keep that case
        // strict, while allowing normal cell boxes to follow a photographed
        // table's slight perspective.
        if largerHeight / smallerHeight > 2.5 {
            return yCenterDiff <= smallerHeight * 0.5
                && overlap >= smallerHeight * 0.5
        }

        let centerTolerance = largerHeight * 0.8
        let overlapTolerance = smallerHeight * 0.25
        return yCenterDiff <= centerTolerance
            && (overlap >= overlapTolerance
                || abs(a.minY - b.minY) <= largerHeight * 0.5)
    }

    private static func centerY(_ boxes: [RawTextBox]) -> CGFloat {
        boxes.map { $0.boundingBox.midY }.reduce(0, +) / CGFloat(boxes.count)
    }
}
