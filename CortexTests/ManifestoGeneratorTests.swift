import XCTest
@testable import Cortex

final class ManifestoGeneratorTests: XCTestCase {
    func testManifestoIncludesIdentityAndMission() {
        let text = ManifestoGenerator.make(realName: "Lia", alterName: "Guardião", mission: "Estudar diariamente")
        XCTAssertTrue(text.contains("Guardião"))
        XCTAssertTrue(text.contains("Estudar diariamente"))
        XCTAssertTrue(text.contains("sem vergonha"))
    }
}
