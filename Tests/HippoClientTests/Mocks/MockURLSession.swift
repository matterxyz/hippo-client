//
//  MockURLSession.swift
//  hippo-internal
//
//  Created by Nick Sloan on 9/26/24.
//
import HippoClient
import Foundation
import HTTPTypes

class MockURLSession: HTTPRequestable, @unchecked Sendable {
    nonisolated(unsafe) var requestHandlers: [(HTTPRequest, Data?) throws -> (HTTPResponse, Data)] = .init()
    
    func data(for request: HTTPTypes.HTTPRequest) async throws -> (Data, HTTPTypes.HTTPResponse) {
        let (response, body) = try requestHandlers.removeFirst()(request, nil)
        return (body, response)
    }
    
    func upload(for request: HTTPTypes.HTTPRequest, from data: Data) async throws -> (Data, HTTPTypes.HTTPResponse) {
        let (response, body) = try requestHandlers.removeFirst()(request, data)
        return (body, response)
    }
}
