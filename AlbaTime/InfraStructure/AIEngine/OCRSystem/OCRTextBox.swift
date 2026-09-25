//
//  OCRTextBox.swift
//  AlbaTime
//
//  Created by 이준희 on 9/13/26.
//

import Foundation
import CoreGraphics

struct OCRTextAlternative: Sendable, Equatable {
    let text: String
    let confidence: Float
}

struct RawTextBox: Sendable {
    let text: String
    let boundingBox: CGRect
    let confidence: Float
    let alternatives: [OCRTextAlternative]

    init(text: String, boundingBox: CGRect, confidence: Float = 1,
         alternatives: [OCRTextAlternative] = []) {
        self.text = text
        self.boundingBox = boundingBox
        self.confidence = confidence
        self.alternatives = alternatives
    }
}

/// Preserve the original cell geometry while supplemental passes fill gaps.
enum OCRCandidateMerger {
    static func merge(primary: [RawTextBox], supplemental: [RawTextBox]) -> [RawTextBox] {
        var result = primary.sorted(by: readingOrder)
        
        for candidate in supplemental.sorted(by: readingOrder) {
            let overlapping = result.indices.filter { sameRegion(result[$0], candidate) }
            
            guard !overlapping.isEmpty else {
                result.append(candidate)
                continue
            }
            
            // A broad observation covering multiple cells is not a replacement.
            guard overlapping.count == 1, let index = overlapping.first else { continue }
            
            let original = result[index]
            
            let widthRatio = min(original.boundingBox.width, candidate.boundingBox.width)
                / max(original.boundingBox.width, candidate.boundingBox.width)
            
            guard widthRatio >= 0.7 else { continue }
            
            let options = original.alternatives + candidate.alternatives + [
                OCRTextAlternative(text: original.text, confidence: original.confidence),
                OCRTextAlternative(text: candidate.text, confidence: candidate.confidence)
            ]
            
            // Length alone is not evidence of correctness. Compare like-sized
            // tokens and retain alternatives instead of expanding their boxes.
            let useCandidate = compact(original.text).count == compact(candidate.text).count
                && candidate.confidence > original.confidence
            
            let selected = useCandidate ? candidate : original
            
            let alternatives = Dictionary(grouping: options, by: \.text)
                .compactMap { $0.value.max { $0.confidence < $1.confidence } }
                .sorted { $0.confidence == $1.confidence ? $0.text < $1.text : $0.confidence > $1.confidence }
            
            result[index] = RawTextBox(
                text: selected.text,
                boundingBox: original.boundingBox,
                confidence: selected.confidence,
                alternatives: alternatives
            )
        }
        
        return result.sorted(by: readingOrder)
    }

    private static func sameRegion(_ a: RawTextBox, _ b: RawTextBox) -> Bool {
        let smallerHeight = min(a.boundingBox.height, b.boundingBox.height)
        
        guard smallerHeight > 0,
              abs(a.boundingBox.midY - b.boundingBox.midY) <= smallerHeight * 0.5 else {
            return false
        }
        
        let intersection = a.boundingBox.intersection(b.boundingBox)
        
        let smallerArea = min(a.boundingBox.width * a.boundingBox.height,
                              b.boundingBox.width * b.boundingBox.height)
        
        guard !intersection.isNull, smallerArea > 0 else { return false }
        
        return intersection.width * intersection.height / smallerArea >= 0.5
    }

    private static func compact(_ text: String) -> String {
        text.uppercased().filter { !$0.isWhitespace }
    }

    private static func readingOrder(_ a: RawTextBox, _ b: RawTextBox) -> Bool {
        if a.boundingBox.midY != b.boundingBox.midY {
            return a.boundingBox.midY > b.boundingBox.midY
        }
        
        if a.boundingBox.minX != b.boundingBox.minX {
            return a.boundingBox.minX < b.boundingBox.minX
        }
        
        if a.confidence != b.confidence { return a.confidence > b.confidence }
        
        return a.text < b.text
    }
}

/// Keep spaced time/date expressions together. Vision supplies token coordinates.
enum OCRTextTokenizer {
    private static let tokens = try! NSRegularExpression(pattern:
        #"\d{4}\s*[년./-]\s*\d{1,2}\s*[월./-]\s*\d{1,2}\s*일?|[0-9OoIiLl]{1,2}\s*시(?:\s*[0-9]{1,2}\s*분?)?\s*[~～〜\-–—]\s*[0-9OoIiLl]{1,2}\s*시(?:\s*[0-9]{1,2}\s*분?)?(?![0-9OoIiLl:.;])|[0-9OoIiLl]{1,2}(?:\s*[:.;；시]\s*[0-9OoIiLl]{2})?\s*[~～〜\-–—]\s*[0-9OoIiLl]{1,2}(?:\s*[:.;；시]\s*[0-9OoIiLl]{2})?(?![0-9OoIiLl:.;])|\d{1,2}\s*[월./]\s*\d{1,2}\s*일?|[^\s()]+|[()]"#)

    static func ranges(in text: String) -> [Range<String.Index>] {
        tokens.matches(in: text, range: NSRange(text.startIndex..., in: text))
            .compactMap { Range($0.range, in: text) }
    }
}
