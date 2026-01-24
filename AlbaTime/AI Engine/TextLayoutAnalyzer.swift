//
//  TextLayoutAnalyzer.swift
//  AlbaTime
//
//  Created by 이준희 on 1/17/26.
//

// 존재 이유: OCR의 단어 좌표들 한줄 텍스트로 복원, 사람 시각 모델링

import Foundation

// x축 기반으로 인식률 높이기 위해 추가
struct TextElement {
    let text: String
    let midX: CGFloat
}

/// 같은 라인(행)에 있는 텍스트 박스들의 묶음 (구조화 단계에서 사용)
struct TextRow {
    let elements: [TextElement]
    
    // 행 전체 텍스트 반환 (공백으로 연결)
    var fullText: String {
        return elements.map {$0.text}.joined(separator: " ")
    }
}

// 존재 이유: OCR은 기본적으로 단어 조각 단위로 나오기에 내가 필요한 날짜, 시간, 이름이 있는 한줄을 얻지 못하여 존재
// 파서를 위한 중간 구조

final class TextLayoutAnalyzer {
    
    /// 뒤죽박죽인 텍스트 박스들을 '행(Row)' 단위로 그룹화 // 텍스트 박스들 같은 줄인지 다른 줄인지 판단
    static func groupByRow(_ boxes: [RawTextBox]) -> [TextRow] {
        
        guard !boxes.isEmpty else { return [] }
        
        let validBoxes = boxes.filter {
            !$0.text.trimmingCharacters(in: .whitespaces).isEmpty
        }
        
        // Vision 좌표계: y가 클수록 위
        let sortedByY = validBoxes.sorted {
            $0.boundingBox.maxY > $1.boundingBox.maxY
        }
        
        var rows: [[RawTextBox]] = []
        
        for box in sortedByY {
            if let index = rows.firstIndex(where: {
                isSameLine($0.first!.boundingBox, box.boundingBox)
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
        let overlap = min(a.maxY, b.maxY) - max(a.minY, b.minY)
        return overlap > min(a.height, b.height) * 0.5
    }
}


