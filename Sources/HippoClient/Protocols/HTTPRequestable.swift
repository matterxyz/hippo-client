//
//  HTTPRequestable.swift
//  hippo-internal
//
//  Created by Nick Sloan on 9/26/24.
//
import Foundation
import HTTPTypes
import HTTPTypesFoundation


public protocol HTTPRequestable: Sendable {
    func data(for request: HTTPRequest) async throws -> (Data, HTTPResponse)
    func upload(for request: HTTPRequest, from bodyData: Data) async throws -> (Data, HTTPResponse)
    func upload(for request: HTTPRequest, fromFile fileURL: URL) async throws -> (Data, HTTPResponse)
}

extension URLSession: HTTPRequestable {}
