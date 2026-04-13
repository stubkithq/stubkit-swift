import XCTest
@testable import Stubkit

final class StubkitTests: XCTestCase {
    func testEntitlementStatusDecoding() {
        XCTAssertEqual(EntitlementStatus(rawValue: "active"), .active)
        XCTAssertEqual(EntitlementStatus(rawValue: "grace"), .grace)
        XCTAssertEqual(EntitlementStatus(rawValue: "expired"), .expired)
        XCTAssertEqual(EntitlementStatus(rawValue: "cancelled"), .cancelled)
        XCTAssertEqual(EntitlementStatus(rawValue: "refunded"), .refunded)
    }

    func testPlatformDecoding() {
        XCTAssertEqual(Platform(rawValue: "ios"), .ios)
        XCTAssertEqual(Platform(rawValue: "android"), .android)
        XCTAssertEqual(Platform(rawValue: "web"), .web)
    }

    func testRawEntitlementToDomain() {
        let raw = RawEntitlement(
            id: "pro",
            status: "active",
            expires_at: "2026-12-31T23:59:59Z",
            source: "iap",
            platform: "ios",
            product_id: "com.example.pro"
        )
        let domain = raw.toDomain()
        XCTAssertEqual(domain.id, "pro")
        XCTAssertEqual(domain.status, .active)
        XCTAssertNotNil(domain.expiresAt)
        XCTAssertEqual(domain.source, .iap)
        XCTAssertEqual(domain.platform, .ios)
        XCTAssertEqual(domain.productId, "com.example.pro")
    }
}
