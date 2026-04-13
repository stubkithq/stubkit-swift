import Foundation

/// Error returned by Stubkit API calls.
public struct StubkitError: LocalizedError, Sendable {
    /// Human-readable error message.
    public let message: String
    /// Machine-readable error code (e.g. `"unauthenticated"`, `"not_found"`).
    public let code: String
    /// HTTP status code from the API.
    public let statusCode: Int

    public var errorDescription: String? { message }
}
