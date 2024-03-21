//
//  HandleSearchMock.swift
//  
//
//  Created by Yusuf Özgül on 21.03.2024.
//

import FlyingFox
import Foundation
@preconcurrency import CommonKit

public protocol ServerMockSearchHandlerInterface {
    func search(path: String, method: String, scenario: String?, rawFlags: [String: String]) async throws -> (status: Int, body: Data, headers: [String: String])
}

final class HandleSearchMock: HTTPHandler {
    static var handler: ServerMockSearchHandlerInterface?
    private let jsonDecoder = JSONDecoder()
    private let logger = Logger(category: "HandleSearchMock")

    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        logger.debug("New request handled")

        guard let handler = HandleSearchMock.handler else {
            logger.fault("Handler not registered, you should register handler before handling requests")
            return .init(statusCode: .notImplemented)
        }
        let bodyData = try await request.bodyData
        let searchRequest = try jsonDecoder.decode(MockServerSearchRequestModel.self, from: bodyData)
        let rawFlags: [String: String] = Dictionary(uniqueKeysWithValues: request.headers.map { ($0.key.rawValue, $0.value) })

        do {
            let result = try await handler.search(path: searchRequest.path,
                                                  method: searchRequest.method,
                                                  scenario: searchRequest.scenario,
                                                  rawFlags: rawFlags)
            return .init(statusCode: .init(result.status, phrase: ""),
                         headers: Dictionary(uniqueKeysWithValues: HeaderFilter.filter(result.headers).map { key, value in  (HTTPHeader(key), value.lowercased()) }),
                         body: result.body)
        } catch {
            logger.error("Handle mock try error: \(error)")
            throw error
        }
    }
}

private struct MockServerSearchRequestModel: Codable {
    let method: String
    let path: String
    let scenario: String
}
