import Foundation

/// Main entry point for the Stubkit SDK.
///
/// Configure once at app launch, then call `isActive` anywhere:
/// ```swift
/// Stubkit.configure(apiKey: "pk_live_xxx", appId: "myapp")
/// let isPro = try await Stubkit.shared.isActive(userId: "u123", entitlement: "pro")
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
    public static func configure(apiKey: String, appId: String, baseURL: String = "https://api.stubkit.com") {
        _shared = Stubkit(apiKey: apiKey, appId: appId, baseURL: baseURL)
    }

    // MARK: - Private

    private static nonisolated(unsafe) var _shared: Stubkit?

    private let http: StubkitHTTP
    private let appId: String

    private init(apiKey: String, appId: String, baseURL: String) {
        self.appId = appId
        self.http = StubkitHTTP(apiKey: apiKey, baseURL: baseURL)
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

    /// Get all entitlements for a user.
    public func getEntitlements(userId: String) async throws -> [Entitlement] {
        let path = "/v1/entitlement/\(appId)/\(userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? userId)"
        let response: EntitlementResponse = try await http.get(path: path)
        return response.entitlements.map { $0.toDomain() }
    }

    /// Sync an in-app purchase receipt with Stubkit.
    public func syncPurchase(userId: String, platform: Platform, productId: String, receipt: String, transactionId: String? = nil) async throws -> [Entitlement] {
        let body = SyncPurchaseBody(
            app_id: appId,
            platform: platform.rawValue,
            product_id: productId,
            receipt: receipt,
            transaction_id: transactionId,
            user_id: userId
        )
        let response: EntitlementResponse = try await http.post(path: "/v1/purchases", body: body)
        return response.entitlements.map { $0.toDomain() }
    }

    /// Force refresh entitlements (bypass cache).
    public func refresh(userId: String) async throws -> [Entitlement] {
        let path = "/v1/entitlement/\(appId)/\(userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? userId)/refresh"
        let response: EntitlementResponse = try await http.post(path: path)
        return response.entitlements.map { $0.toDomain() }
    }
}
