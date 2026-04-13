import Foundation

// MARK: - Public Types

public enum Platform: String, Sendable {
    case ios
    case android
    case web
}

public enum EntitlementStatus: String, Sendable, Codable {
    case active
    case grace
    case expired
    case cancelled
    case refunded
}

public enum EntitlementSource: String, Sendable, Codable {
    case iap
    case stripe
    case adminGrant = "admin_grant"
    case trial
}

public struct Entitlement: Sendable {
    public let id: String
    public let status: EntitlementStatus
    public let expiresAt: Date?
    public let source: EntitlementSource
    public let platform: Platform
    public let productId: String
}

// MARK: - Internal API Types

struct EntitlementResponse: Decodable {
    let app_id: String
    let user_id: String
    let entitlements: [RawEntitlement]
}

struct RawEntitlement: Decodable {
    let id: String
    let status: String
    let expires_at: String?
    let source: String
    let platform: String
    let product_id: String

    func toDomain() -> Entitlement {
        let iso = ISO8601DateFormatter()
        return Entitlement(
            id: id,
            status: EntitlementStatus(rawValue: status) ?? .expired,
            expiresAt: expires_at.flatMap { iso.date(from: $0) },
            source: EntitlementSource(rawValue: source) ?? .iap,
            platform: Platform(rawValue: platform) ?? .ios,
            productId: product_id
        )
    }
}

struct SyncPurchaseBody: Encodable {
    let app_id: String
    let platform: String
    let product_id: String
    let receipt: String
    let transaction_id: String?
    let user_id: String
}
