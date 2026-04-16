import Foundation

/// Main entry point for the Stubkit SDK.
///
/// Configure once at app launch with your publishable key AND a callback that
/// returns your tenant's JWT (end-user identity token). Offering/event calls
/// use the publishable key; entitlement/purchase calls use the tenant JWT.
///
/// ```swift
/// Stubkit.configure(
///     publishableKey: "pk_live_xxx",
///     appId: "your-app-id",
///     getAuthToken: { try await authProvider.currentAccessToken() }
/// )
/// let isPro = try await Stubkit.shared.isActive(userId: "u123", entitlement: "pro")
/// let offering = try await Stubkit.shared.getOffering()
/// ```
public final class Stubkit: Sendable {

    /// Shared instance — available after `configure()`.
    public static var shared: Stubkit {
        guard let instance = _shared else {
            fatalError("Stubkit.configure() must be called before accessing .shared")
        }
        return instance
    }

    /// Configure the SDK. Call once, typically in `AppDelegate` or `@main App.init`.
    ///
    /// - Parameters:
    ///   - publishableKey: `pk_live_...` / `pk_test_...` — safe to ship in your app bundle.
    ///   - appId: Your stubkit app identifier.
    ///   - getAuthToken: Async closure returning your tenant JWT. Called on every
    ///     entitlement/purchase request; cache your token upstream if needed.
    ///   - baseURL: Override for staging / self-hosted. Defaults to the SaaS endpoint.
    public static func configure(
        publishableKey: String,
        appId: String,
        getAuthToken: @escaping @Sendable () async throws -> String,
        baseURL: String = "https://api.stubkit.com"
    ) {
        _shared = Stubkit(
            publishableKey: publishableKey,
            appId: appId,
            getAuthToken: getAuthToken,
            baseURL: baseURL
        )
    }

    // MARK: - Private

    private static nonisolated(unsafe) var _shared: Stubkit?

    private let http: StubkitHTTP
    private let appId: String

    private init(
        publishableKey: String,
        appId: String,
        getAuthToken: @escaping @Sendable () async throws -> String,
        baseURL: String
    ) {
        self.appId = appId
        self.http = StubkitHTTP(
            publishableKey: publishableKey,
            getAuthToken: getAuthToken,
            baseURL: baseURL
        )
    }

    // MARK: - Public API

    /// Check if a user has an active entitlement.
    public func isActive(userId: String, entitlement: String) async throws -> Bool {
        let entitlements = try await getEntitlements(userId: userId)
        guard let match = entitlements.first(where: { $0.id == entitlement }) else {
            return false
        }
        switch match.status {
        case .active, .grace:
            return true
        case .cancelled:
            if let exp = match.expiresAt, exp > Date() { return true }
            return false
        case .expired, .refunded:
            return false
        }
    }

    /// Get all entitlements for a user. Uses the tenant JWT.
    public func getEntitlements(userId: String) async throws -> [Entitlement] {
        let escaped = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? userId
        let path = "/v1/entitlement/\(appId)/\(escaped)"
        let response: EntitlementResponse = try await http.get(path: path, auth: .tenantJwt)
        return response.entitlements.map { $0.toDomain() }
    }

    /// Sync an in-app purchase receipt with Stubkit. Uses the tenant JWT.
    public func syncPurchase(
        userId: String,
        platform: Platform,
        productId: String,
        receipt: String,
        transactionId: String? = nil
    ) async throws -> [Entitlement] {
        let body = SyncPurchaseBody(
            app_id: appId,
            platform: platform.rawValue,
            product_id: productId,
            receipt: receipt,
            transaction_id: transactionId,
            user_id: userId
        )
        let response: EntitlementResponse = try await http.post(
            path: "/v1/purchases",
            body: body,
            auth: .tenantJwt
        )
        return response.entitlements.map { $0.toDomain() }
    }

    /// Force refresh entitlements (bypass cache). Uses the tenant JWT.
    public func refresh(userId: String) async throws -> [Entitlement] {
        let escaped = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? userId
        let path = "/v1/entitlement/\(appId)/\(escaped)/refresh"
        let response: EntitlementResponse = try await http.post(path: path, auth: .tenantJwt)
        return response.entitlements.map { $0.toDomain() }
    }

    /// Fetch paywall config (title, subtitle, features, products). Uses the publishable key.
    public func getOffering(slug: String = "default", locale: String? = nil) async throws -> Offering {
        let localeQuery = locale.map { "?locale=\($0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0)" } ?? ""
        let path = "/v1/offerings/\(appId)/\(slug)\(localeQuery)"
        let raw: RawOffering = try await http.get(path: path, auth: .publishable)
        return raw.toDomain()
    }

    /// Record a behavioural event. Server may respond with a paywall suggestion
    /// when an event-rule matches for the user. Uses the publishable key.
    public func track(
        event: String,
        properties: [String: StubkitValue] = [:],
        userId: String
    ) async throws -> TrackResult {
        let body = TrackBody(
            event: event,
            properties: properties,
            user_id: userId
        )
        let raw: RawTrackResponse = try await http.post(
            path: "/v1/events/track",
            body: body,
            auth: .publishable
        )
        return raw.toDomain()
    }
}
