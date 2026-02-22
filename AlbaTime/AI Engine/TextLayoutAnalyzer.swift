//
//  TextLayoutAnalyzer.swift
//  AlbaTime
//
//  Created by 이준희 on 1/17/26.
//

import Foundation

// 해당하는 텍스트가 행 안에서 어느열에 있는지를 표현
struct TextElement {
    let text: String // OCR로 인식된 문자열
    let midX: CGFloat // 해당 텍스트 박스의 가로 중심값
}

// OCR 텍스트를 파서에서 다루기 쉬운 행 단위로 묶은 구조
// 파서가 줄 단위로 해석할 수 있는 기본 단위
struct TextRow {
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
            !$0.text.trimmingCharacters(in: .whitespaces).isEmpty
        }
        
        // Vision 좌표계: y가 클수록 위 // y축 기준 정렬
        let sortedByY = validBoxes.sorted {
            $0.boundingBox.maxY > $1.boundingBox.maxY
        }
        
        var rows: [[RawTextBox]] = []
        
        for box in sortedByY {
            if let index = rows.firstIndex(where: {
                guard let first = $0.first else { return false }
                return isSameLine(first.boundingBox, box.boundingBox)
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
                    TextElement(text: $0.text, midX: $0.boundingBox.midX)
                }
            )
        }
    }
    
    private static func isSameLine(_ a: CGRect, _ b: CGRect) -> Bool {
        // 기울기/원근이 있는 사진에서도 줄 묶음이 흔들리지 않도록
        // Y 중심 거리와 겹침 비율을 함께 사용한다.
        let yCenterDiff = abs(a.midY - b.midY)
        let dynamic = max(a.height, b.height) * 0.8
        let overlap = min(a.maxY, b.maxY) - max(a.minY, b.minY)
        return yCenterDiff <= dynamic || overlap > min(a.height, b.height) * 0.35
    }
}

