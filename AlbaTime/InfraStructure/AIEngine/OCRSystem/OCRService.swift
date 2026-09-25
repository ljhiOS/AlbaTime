//
//  TextLayoutAnalyzer.swift
//  AlbaTime
//
//  Created by 이준희 on 1/17/26.
//

import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import ImageIO

final class OCRService: Sendable {
    static let shared = OCRService()
    private init() {}

    // TODO: costomWords에서 타겟네임과 프리셋 라벨을 합쳐서 보낼 필요가 있는지 검증해야함
    func recognize(from image: UIImage, customWords: [String] = []) async throws -> [RawTextBox] {
        let context = CIContext()
        
        guard let original = orientedImage(image, context: context) else { return [] }
        
        let primary = try await recognizeVariant(original, customWords: customWords)
        try Task.checkCancellation()

        // Average confidence cannot prove that small names/date headers were found.
        guard let enhanced = enhancedImage(original, ciContext: context) else { return primary }
        
        do {
            let supplemental = try await recognizeVariant(enhanced, customWords: customWords)
            try Task.checkCancellation()
            return OCRCandidateMerger.merge(primary: primary, supplemental: supplemental)
        } catch {
            try Task.checkCancellation()
            if !primary.isEmpty { return primary }
            throw error
        }
    }

    private func recognizeVariant(_ image: CGImage, customWords: [String]) async throws -> [RawTextBox] {
        try Task.checkCancellation()
        
        var request = RecognizeTextRequest()
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = [Locale.Language(identifier: "ko-KR"), Locale.Language(identifier: "en-US")]
        request.usesLanguageCorrection = true
        request.customWords = customWords.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        request.minimumTextHeightFraction = 0
        
        let observations: [RecognizedTextObservation] = try await request.perform(on: image, orientation: .up)
        
        try Task.checkCancellation()
        
        return observations.flatMap { observation -> [RawTextBox] in
            let candidates: [RecognizedText] = observation.topCandidates(3)
            
            guard let first = candidates.first else { return [] }
            
            let ranges = OCRTextTokenizer.ranges(in: first.string)
            guard !ranges.isEmpty else { return [] }
            
            let alternatives = candidates.map { OCRTextAlternative(text: $0.string, confidence: $0.confidence) }
            
            if ranges.count > 1 {
                let rawTextBoxes: [RawTextBox] = ranges.compactMap { range -> RawTextBox? in
                    guard let box = first.boundingBox(for: range) else { return nil }
                    
                    return RawTextBox(
                        text: String(first.string[range]),
                        boundingBox: box.boundingBox.cgRect,
                        confidence: first.confidence
                    )
                }
                
                if rawTextBoxes.count == ranges.count { return rawTextBoxes }
            }
            
            return [RawTextBox(text: first.string.trimmingCharacters(in: .whitespacesAndNewlines),
                               boundingBox: observation.boundingBox.cgRect,
                               confidence: first.confidence, alternatives: alternatives)]
        }
    }

    private func orientedImage(_ image: UIImage, context: CIContext) -> CGImage? {
        guard let cgImage = image.cgImage else {
            // CIIMage 기반 UIImage를 CGImage로 변환하는 예외 경로
            guard let ciImage = image.ciImage else { return nil }
            let oriented = ciImage.oriented(image.imageOrientation.cgOrientation)
            return context.createCGImage(oriented, from: oriented.extent)
        }
        
        // 이미 정상 방향이면 불필요한 렌더링 생략
        if image.imageOrientation == .up { return cgImage }
        
        // Vision OCR 전에 이미지 방향 정보를 실제 픽셀에 반영
        let oriented = CIImage(cgImage: cgImage).oriented(image.imageOrientation.cgOrientation)
        return context.createCGImage(oriented, from: oriented.extent)
    }

    private func enhancedImage(_ image: CGImage, ciContext: CIContext) -> CGImage? {
        var ciImage = CIImage(cgImage: image)
        
        // Bound resampling by the long edge; large photos do not need 4x pixels.
        let resizeScale = min(2, max(1, 1600 / CGFloat(max(image.width, image.height))))
        
        if resizeScale > 1 {
            let scale = CIFilter.lanczosScaleTransform()
            scale.inputImage = ciImage
            scale.scale = Float(resizeScale)
            scale.aspectRatio = 1
            ciImage = scale.outputImage ?? ciImage
        }
        
        let colorControl = CIFilter.colorControls()
        colorControl.inputImage = ciImage
        colorControl.saturation = 0
        colorControl.contrast = 1.15
        
        let processedCIImage = colorControl.outputImage ?? ciImage
        
        return ciContext.createCGImage(processedCIImage, from: processedCIImage.extent)
    }
}

private extension UIImage.Orientation {
    var cgOrientation: CGImagePropertyOrientation {
        switch self {
        case .up: return .up
        case .upMirrored: return .upMirrored
        case .down: return .down
        case .downMirrored: return .downMirrored
        case .left: return .left
        case .leftMirrored: return .leftMirrored
        case .right: return .right
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
