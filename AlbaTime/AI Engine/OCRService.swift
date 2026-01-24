//
//  OCRService.swift
//  AlbaTime
//
//  Created by 이준희 on 1/17/26.
//

// 용도: 이미지에서 텍스트를 안정적으로 추출하기 위한 OCR 전용 계층
// Clean Architecture: 단일 책임 원칙(SRP)

import UIKit //func recognize(from image: UIImage) 때문에 임포트 필요(Vision은 UIImage를 직접 받지 않기 때문에)
import Vision // vn~~~ OCR 핵심 엔진 / 이미지 -> 텍스트 추출하는 AI 엔진
import CoreImage // CI~~ GPU 가속 지원, 이미지 전처리 / 필터 / 변환 프레임 워크 / OCR전 이미지 품질 높이려고 임포트
import CoreImage.CIFilterBuiltins // CoreImage 필터를 타입 안전하게 쓰게 해주는 모듈 / 이미지 필터를 안전하고 간결하게 쓰기 위한 확장 모듈

// MARK: - Data Models

/// OCR이 인식한 원시 텍스트 박스 데이터 (위치 정보 포함)
struct RawTextBox {
    let text: String
    let boundingBox: CGRect // 정규화된 좌표 (0~1)
}
// 존재 이유: VNRecognizedTextObservation 타입의 문제점 1) Vision에 강하게 의존 2) 테스트 어려움 3) 파서가 Vision 타입을 직접 알게 됨 X
// 이라는 문제점을 보완하기 위해 Vision 결과를 앱 도메인 모델로 변환 OCRService 이후 단계는 Vision을 전혀 모른채 텍스트로만 다룰 수 있음 -> 계층 분리 설계

// MARK: - Service

final class OCRService { // final인 이유: 1) 상속 의도 없음, 2) 서비스객체, 3) 성능 최적화 가능
    
    static let shared = OCRService() // Static인 이유: 1) 상태 업음 2) 여러 View에서 동일하게 사용 3) 무거운 초기화 없음
    private init() {}
    
    /// 이미지에서 텍스트를 추출하여 RawTextBox 배열로 반환
    /// async -> OCR은 비동기 작업, throws -> Vision 실패 가능 핸들링
    func recognize(from image: UIImage) async throws -> [RawTextBox] {
        // 1. 이미지 전처리 (대비 강화 -> 인식률 상승 핵심)
        guard let cgImage = preprocess(image).cgImage else { return [] }
        // Vision은 CGImage 및 CVPixelBuffer만 처리 가능하기에 이 코드가 없다면 Vision 요청 자체가 불가능, OCR 정확도 급락(전처리 자체가 없기에)
        // 도메인 모델
        return try await withCheckedThrowingContinuation { cont in // 왜 필요할까 Vision API는 콜백 기반, 동시성은 async, await기반 시대 차이 징검다리 역할 / 없다면? 무수한 콜백, 뷰모델에서 await 못 씀
            // Vision 엔진 OCR 끝내고 실행 존재 이유: 에러 처리, 결과 변환
            let request = VNRecognizeTextRequest { req, error in
                if let error = error {
                    cont.resume(throwing: error)
                    return
                }
                
                // 2. 결과 매핑
                // Vision의 Results는 [Any]?기에 타입 안정성 확보를 위한 캐스팅 (as)
                let boxes = (req.results as? [VNRecognizedTextObservation])?
                    .compactMap { observation -> RawTextBox? in
                        guard let candidate = observation.topCandidates(1).first else { return nil } // OCR은 여러개 후보를 제시하지만 최고 신뢰도인 1개만 필요
                        // OCR -> 구조화 파이프라인 텍스트 / 다음 단계 행,열 판단용
                        return RawTextBox(
                            text: candidate.string,
                            boundingBox: observation.boundingBox
                        )
                    } ?? []
                // resume 없으면 앱 멈춤 why? await 무한 대기 -> 동시성 복습 필요
                cont.resume(returning: boxes)
            }
            
            // 3. 인식 옵션 설정
            request.recognitionLanguages = ["ko-KR", "en-US"]
            request.recognitionLevel = .accurate // 속도보다 정확도 우선
            request.usesLanguageCorrection = true // 한국어 띄어쓰기 보정
            request.minimumTextHeight = 0.0     // 표 배경 노이즈 제거
            
            // 요청 실행
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request]) // 트리거
        }
    }
    
    /// 전처리: 대비를 높이고 채도를 낮춤 (흑백 문서처럼 만듦) -> 분리 이유 OCR 핵심 로직과 관심사 분리, 성능 튜닝
    private func preprocess(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        // 1. 흑백 변환 (색상 노이즈 제거)
        let noir = CIFilter.photoEffectNoir()
        noir.inputImage = ciImage
        guard let grayImage = noir.outputImage else { return image }
        
        // 2. 해상도 확대 (작은 글씨 보정용, 2배면 충분)
        // Lanczos는 텍스트를 부드럽게 만들어서 오히려 디지털 폰트에 안 좋을 수 있음 -> 단순 확대 사용
        let scale = CIFilter.lanczosScaleTransform()
        scale.inputImage = grayImage
        scale.scale = 2.0
        scale.aspectRatio = 1.0
        
        guard let outputImage = scale.outputImage else { return image }
        
        // 3. (제거됨) 과도한 대비(Contrast)와 선명효과(Sharpen)는 디지털 폰트를 망가뜨림
        
        let context = CIContext(options: [.useSoftwareRenderer: false])
        if let cg = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cg)
        }
        return image
    }
}
