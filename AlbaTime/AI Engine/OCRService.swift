//
//  OCRService.swift
//  AlbaTime
//
//  Created by 이준희 on 1/17/26.
//

import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

struct RawTextBox {
    let text: String
    let boundingBox: CGRect
}

final class OCRService {
    private struct CandidateBox {
        let text: String
        let boundingBox: CGRect
        let confidence: Float
    }

    // 공용의 OCR 사용 -> 싱글톤 패턴
    static let shared = OCRService()
    private init() {}

    // 멀티패스 OCR:
    // 1) 기본 패스를 먼저 실행하고 품질이 충분하면 종료
    // 2) 부족할 때만 보조 패스를 병렬 실행해 정확도를 보완
    func recognize(from image: UIImage) async throws -> [RawTextBox] {
        let variants = preprocessVariants(image)
        guard !variants.isEmpty else { return [] }

        let minimumTextHeight = tunedMinimumTextHeight(for: image)
        let firstPass = try await recognizeVariant(variants[0], minimumTextHeight: minimumTextHeight)

        if shouldSkipAdditionalPass(firstPass) || variants.count == 1 {
            return mergeCandidates(firstPass)
        }

        let others = Array(variants.dropFirst())
        let rest = try await recognizeVariantsInParallel(others, minimumTextHeight: minimumTextHeight)
        return mergeCandidates(firstPass + rest)
    }

    private func recognizeVariantsInParallel(_ images: [UIImage], minimumTextHeight: Float) async throws -> [CandidateBox] {
        try await withThrowingTaskGroup(of: [CandidateBox].self) { group in
            for image in images {
                group.addTask { [self] in
                    try await recognizeVariant(image, minimumTextHeight: minimumTextHeight)
                }
            }

            var all: [CandidateBox] = []
            for try await boxes in group {
                all.append(contentsOf: boxes)
            }
            return all
        }
    }

    private func recognizeVariant(_ image: UIImage, minimumTextHeight: Float) async throws -> [CandidateBox] {
        guard let cgImage = image.cgImage else { return [] }

        return try await withCheckedThrowingContinuation { cont in
            let request = VNRecognizeTextRequest { req, error in
                if let error {
                    cont.resume(throwing: error)
                    return
                }

                let boxes = (req.results as? [VNRecognizedTextObservation])?
                    .compactMap { observation -> CandidateBox? in
                        guard let candidate = observation.topCandidates(1).first else { return nil }
                        guard candidate.confidence >= 0.18 else { return nil }

                        let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { return nil }

                        return CandidateBox(
                            text: text,
                            boundingBox: observation.boundingBox,
                            confidence: candidate.confidence
                        )
                    } ?? []

                cont.resume(returning: boxes)
            }

            request.recognitionLanguages = ["ko-KR", "en-US"]
            request.recognitionLevel = .accurate
            // 이름/한글 문장 인식 안정성을 위해 교정을 켠다.
            request.usesLanguageCorrection = true
            request.minimumTextHeight = minimumTextHeight

            do {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try handler.perform([request])
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    // 사진 품질 편차 대응을 위해 서로 다른 전처리 버전을 준비한다.
    private func preprocessVariants(_ image: UIImage) -> [UIImage] {
        guard let ciImage = CIImage(image: image) else { return [image] }
        // CIContext -> Core Image 렌더링 엔진
        let context = CIContext()
        
        let noir = CIFilter.photoEffectNoir()
        noir.inputImage = ciImage
        let gray = noir.outputImage ?? ciImage

        let scale = CIFilter.lanczosScaleTransform()
        scale.inputImage = gray
        scale.scale = 2.0
        scale.aspectRatio = 1.0
        let upscaled = scale.outputImage ?? gray

        let contrast = CIFilter.colorControls()
        contrast.inputImage = upscaled
        contrast.contrast = 1.25
        contrast.saturation = 0.0
        let contrasted = contrast.outputImage ?? upscaled

        let sharp = CIFilter.sharpenLuminance()
        sharp.inputImage = upscaled
        sharp.sharpness = 0.35
        let sharpened = sharp.outputImage ?? upscaled

        let outputs = [upscaled, contrasted, sharpened]
        return outputs.compactMap {
            guard let cg = context.createCGImage($0, from: $0.extent) else { return nil }
            return UIImage(cgImage: cg)
        }
    }

    /// 1차 패스가 충분히 좋은 경우 보조 패스를 생략해 지연 시간을 줄인다.
    private func shouldSkipAdditionalPass(_ boxes: [CandidateBox]) -> Bool {
        guard !boxes.isEmpty else { return false }

        let avgConfidence = boxes.reduce(0.0) { $0 + Double($1.confidence) } / Double(boxes.count)
        let hasScheduleSignal = boxes.contains { box in
            let t = normalizeText(box.text)
            return t.contains(":") || t.contains("-") || t.contains("/") || t.contains("월") || t.contains("OFF")
        }

        return boxes.count >= 12 && avgConfidence >= 0.72 && hasScheduleSignal
    }

    /// 위치(IoU), 중심점 거리, 문자열 유사도를 함께 사용해 중복을 병합한다.
    private func mergeCandidates(_ candidates: [CandidateBox]) -> [RawTextBox] {
        let sorted = candidates.sorted { $0.confidence > $1.confidence }
        var merged: [CandidateBox] = []

        for cand in sorted {
            if let idx = merged.firstIndex(where: { isDuplicate($0, cand) }) {
                merged[idx] = pickBetter(merged[idx], cand)
            } else {
                merged.append(cand)
            }
        }

        return merged
            .sorted {
                if abs($0.boundingBox.midY - $1.boundingBox.midY) > 0.004 {
                    return $0.boundingBox.midY > $1.boundingBox.midY
                }
                return $0.boundingBox.minX < $1.boundingBox.minX
            }
            .map { RawTextBox(text: $0.text, boundingBox: $0.boundingBox) }
    }

    private func pickBetter(_ a: CandidateBox, _ b: CandidateBox) -> CandidateBox {
        if b.confidence > a.confidence + 0.03 { return b }
        if a.confidence > b.confidence + 0.03 { return a }
        return b.text.count >= a.text.count ? b : a
    }

    private func isDuplicate(_ a: CandidateBox, _ b: CandidateBox) -> Bool {
        let overlap = iou(a.boundingBox, b.boundingBox)
        if overlap >= 0.45 { return true }

        let centerDist = hypot(a.boundingBox.midX - b.boundingBox.midX, a.boundingBox.midY - b.boundingBox.midY)
        let textSim = similarity(normalizeText(a.text), normalizeText(b.text))

        return centerDist < 0.02 && textSim >= 0.7
    }

    private func tunedMinimumTextHeight(for image: UIImage) -> Float {
        let shortSide = min(image.size.width, image.size.height) * image.scale
        switch shortSide {
        case ..<1000: return 0.018
        case ..<1500: return 0.014
        case ..<2200: return 0.012
        default: return 0.010
        }
    }

    private func iou(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let inter = a.intersection(b)
        guard !inter.isNull else { return 0 }
        let interArea = inter.width * inter.height
        let union = (a.width * a.height) + (b.width * b.height) - interArea
        guard union > 0 else { return 0 }
        return interArea / union
    }

    private func normalizeText(_ text: String) -> String {
        text.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "O", with: "0")
            .replacingOccurrences(of: "I", with: "1")
            .replacingOccurrences(of: "L", with: "1")
    }

    private func similarity(_ lhs: String, _ rhs: String) -> Double {
        if lhs == rhs { return 1.0 }
        guard !lhs.isEmpty && !rhs.isEmpty else { return 0.0 }

        let dist = levenshtein(lhs, rhs)
        let maxLen = max(lhs.count, rhs.count)
        return 1.0 - (Double(dist) / Double(maxLen))
    }

    private func levenshtein(_ a: String, _ b: String) -> Int {
        let aa = Array(a)
        let bb = Array(b)
        if aa.isEmpty { return bb.count }
        if bb.isEmpty { return aa.count }

        var prev = Array(0...bb.count)
        for (i, ca) in aa.enumerated() {
            var cur = [i + 1]
            for (j, cb) in bb.enumerated() {
                let cost = ca == cb ? 0 : 1
                cur.append(min(cur[j] + 1, prev[j + 1] + 1, prev[j] + cost))
            }
            prev = cur
        }
        return prev.last ?? 0
    }
}
