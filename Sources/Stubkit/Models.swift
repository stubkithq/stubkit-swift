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

public struct Offering: Sendable {
    public let slug: String
    public let title: String
    public let subtitle: String?
    public let features: [String]
    public let ctaLabel: String
    public let locale: String?
    public let products: [OfferingProduct]
}

public struct OfferingProduct: Sendable {
    public let productId: String
    public let platform: Platform
    public let periodDays: Int?
    public let priceUsdCents: Int?
    public let entitlement: String
}

public struct TrackResult: Sendable {
    public let matchedRuleId: String?
    public let showPaywall: Offering?
}

/// JSON-compatible scalar/collection values for event properties.
public enum StubkitValue: Sendable, Encodable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let v): try c.encode(v)
        case .int(let v): try c.encode(v)
        case .double(let v): try c.encode(v)
        case .bool(let v): try c.encode(v)
        case .null: try c.encodeNil()
        }
    }
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

struct RawOffering: Decodable {
    let app_id: String
    let slug: String
    let title: String
    let subtitle: String?
    let features: [String]
    let cta_label: String
    let locale: String?
    let products: [RawOfferingProduct]

    func toDomain() -> Offering {
        Offering(
            slug: slug,
            title: title,
            subtitle: subtitle,
            features: features,
            ctaLabel: cta_label,
            locale: locale,
            products: products.map { $0.toDomain() }
        )
    }
}

struct RawOfferingProduct: Decodable {
    let product_id: String
    let platform: String
    let period_days: Int?
    let price_usd_cents: Int?
    let entitlement: String

    func toDomain() -> OfferingProduct {
        OfferingProduct(
            productId: product_id,
            platform: Platform(rawValue: platform) ?? .ios,
            periodDays: period_days,
            priceUsdCents: price_usd_cents,
            entitlement: entitlement
        )
    }
}

struct TrackBody: Encodable {
    let event: String
    let properties: [String: StubkitValue]
    let user_id: String
}

struct RawTrackResponse: Decodable {
    let matched_rule_id: String?
    let show_paywall: RawOffering?

    func toDomain() -> TrackResult {
        TrackResult(
            matchedRuleId: matched_rule_id,
            showPaywall: show_paywall?.toDomain()
        )
    }
}
