import XCTest
@testable import AlbaTime

@MainActor
final class ScheduleImageAnalyzerRoutingTests: XCTestCase {
    func testAnalyzerUsesOCRPipeline() {
        let analyzer = WorkPlaceFeatureComposition.makeScheduleImageAnalyzer()
        XCTAssertTrue(analyzer is AnalyzeScheduleImage)
    }
}
