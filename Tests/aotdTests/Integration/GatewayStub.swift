import Foundation
import MidgarCommerce
import MidgarCore
import os

@testable import aotd

/// A Midgar ID that is always there, in the UUID form `appAccountToken` takes.
nonisolated struct StubIdentity: MidgarStoreIdentity {
    static let midgarID = "9C4E1B2A-7D35-4F80-A1B6-3E5D7F9A0C24"

    var midgarId: String {
        get async throws { Self.midgarID }
    }
}

/// The Midgar gateway in these tests: no request reaches the network. It answers the ledger the store reports to and
/// reads from, and records every request so the test can read what the app sent. It can also be taken down, so a test
/// can prove what works with no network. The state is one lock-guarded value, shared by every request of the process
/// without any unsafe annotation; the suites that use it run serially.
nonisolated final class GatewayStub: URLProtocol {
    struct Request: Sendable {
        let method: String
        let path: String
    }

    private struct State {
        var requests: [Request] = []
        var isDown = false
    }

    private static let host = "gateway.aotd-tests.invalid"
    private static let state = OSAllocatedUnfairLock(initialState: State())

    static let baseURL = URL(string: "https://\(host)")!

    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [GatewayStub.self]
        return URLSession(configuration: configuration)
    }

    static func httpConfiguration() -> MidgarHTTPConfiguration {
        MidgarHTTPConfiguration(baseURL: baseURL, appID: AotdMidgar.appID, session: session(), timeout: 5)
    }

    static func reset() {
        state.withLock { $0 = State() }
    }

    static func setDown(_ isDown: Bool) {
        state.withLock { $0.isDown = isDown }
    }

    static func requests(method: String, pathSuffix: String) -> [Request] {
        state.withLock { $0.requests }.filter { $0.method == method && $0.path.hasSuffix(pathSuffix) }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == host
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let recorded = Request(method: request.httpMethod ?? "GET", path: url.path)
        let answer = Self.answer(to: recorded)
        guard let status = answer.status,
            let response = HTTPURLResponse(
                url: url, statusCode: status, httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"])
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(answer.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func answer(to request: Request) -> (status: Int?, body: String) {
        state.withLock { state in
            state.requests.append(request)
            if state.isDown {
                return (nil, "")
            }
            switch (request.method, request.path) {
            case ("POST", let path) where path.hasSuffix("/v1/ledger/transactions"):
                return (200, #"{"ok":true}"#)
            case ("GET", let path) where path.hasSuffix("/v1/ledger/entitlements"):
                let now = Int(Date().timeIntervalSince1970 * 1000)
                return (200, #"{"midgarId":"\#(StubIdentity.midgarID)","environment":"Sandbox","serverTime":\#(now),"entitlements":[]}"#)
            default:
                return (404, "{}")
            }
        }
    }
}
