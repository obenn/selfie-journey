import Foundation

nonisolated protocol SupportTransport: Sendable {
    func feedback(_ payload: FeedbackPayload) async throws -> String
    func telemetry(_ payload: TelemetryPayload) async throws
}

/// Ephemeral transport has no cookies or HTTP cache. Redirects are rejected so
/// support data cannot be forwarded to a different service by an HTTP redirect.
nonisolated final class SupportURLSession: NSObject, SupportTransport, URLSessionTaskDelegate, @unchecked Sendable {
    private let baseURL: URL
    private let networkingEnabled: Bool

    init(baseURL: URL = URL(string: "https://api.selfiejourney.com")!, networkingEnabled: Bool = true) {
        self.baseURL = baseURL
        self.networkingEnabled = networkingEnabled
    }

    func feedback(_ payload: FeedbackPayload) async throws -> String {
        struct Receipt: Decodable { let receiptId: String }
        let data = try await post(payload, path: "v1/feedback")
        guard let receipt = try? JSONDecoder().decode(Receipt.self, from: data),
              UUID(uuidString: receipt.receiptId) != nil else { throw SupportError.response }
        return receipt.receiptId
    }

    func telemetry(_ payload: TelemetryPayload) async throws {
        _ = try await post(payload, path: "v1/telemetry")
    }

    private func post<Value: Encodable>(_ payload: Value, path: String) async throws -> Data {
        try Task.checkCancellation()
        guard networkingEnabled else { throw SupportError.testing }
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 25
        request.httpBody = try JSONEncoder().encode(payload)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        configuration.waitsForConnectivity = false
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        do {
            let (data, response) = try await session.data(for: request)
            try Task.checkCancellation()
            guard let response = response as? HTTPURLResponse else { throw SupportError.response }
            if response.statusCode == 429 { throw SupportError.rateLimited }
            guard (200..<300).contains(response.statusCode), data.count < 16_384 else { throw SupportError.response }
            return data
        } catch is CancellationError { throw CancellationError() }
        catch let error as URLError where error.code == .cancelled { throw CancellationError() }
        catch let error as SupportError { throw error }
        catch { throw SupportError.unavailable }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}
