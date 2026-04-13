import Foundation

// MARK: - HTTP Client

struct StubkitHTTP: Sendable {
    let apiKey: String
    let baseURL: String

    private let session = URLSession.shared
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .useDefaultKeys
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .useDefaultKeys
        return d
    }()

    func get<T: Decodable>(path: String) async throws -> T {
        try await request(method: "GET", path: path, body: nil as Empty?)
    }

    func post<T: Decodable>(path: String) async throws -> T {
        try await request(method: "POST", path: path, body: nil as Empty?)
    }

    func post<B: Encodable, T: Decodable>(path: String, body: B) async throws -> T {
        try await request(method: "POST", path: path, body: body)
    }

    // MARK: - Internal

    private func request<B: Encodable, T: Decodable>(method: String, path: String, body: B?) async throws -> T {
        let maxRetries = 2
        let baseBackoff: UInt64 = 250_000_000 // 250ms in nanoseconds

        var lastError: Error?

        for attempt in 0...maxRetries {
            do {
                var urlRequest = URLRequest(url: URL(string: "\(baseURL)\(path)")!)
                urlRequest.httpMethod = method
                urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
                urlRequest.setValue("stubkit-swift/1.0.0", forHTTPHeaderField: "User-Agent")

                if let body {
                    urlRequest.httpBody = try encoder.encode(body)
                }

                let (data, response) = try await session.data(for: urlRequest)
                let httpResponse = response as! HTTPURLResponse

                if httpResponse.statusCode >= 500, attempt < maxRetries {
                    try await Task.sleep(nanoseconds: baseBackoff * UInt64(1 << attempt))
                    continue
                }

                if httpResponse.statusCode >= 400 {
                    if let envelope = try? decoder.decode(ErrorEnvelope.self, from: data) {
                        throw StubkitError(
                            message: envelope.error.message,
                            code: envelope.error.code,
                            statusCode: httpResponse.statusCode
                        )
                    }
                    throw StubkitError(
                        message: "HTTP \(httpResponse.statusCode)",
                        code: "http_error",
                        statusCode: httpResponse.statusCode
                    )
                }

                let envelope = try decoder.decode(SuccessEnvelope<T>.self, from: data)
                return envelope.data

            } catch let error as StubkitError {
                throw error
            } catch {
                lastError = error
                if attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: baseBackoff * UInt64(1 << attempt))
                    continue
                }
            }
        }

        throw lastError ?? StubkitError(message: "request failed", code: "unknown", statusCode: 0)
    }
}

// MARK: - Envelope Types

private struct SuccessEnvelope<T: Decodable>: Decodable {
    let success: Bool
    let data: T
}

private struct ErrorEnvelope: Decodable {
    let success: Bool
    let error: ErrorBody
    struct ErrorBody: Decodable {
        let code: String
        let message: String
    }
}

private struct Empty: Encodable {}
