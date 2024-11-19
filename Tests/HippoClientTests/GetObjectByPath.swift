//
//  GetObjectByPath.swift
//  hippo-internal
//
//  Created by Nick Sloan on 9/17/24.
//

import Testing
import Foundation
@testable import HippoClient
import SwiftData
import CryptoKit

@Suite("Get object by path", .serialized)
struct GetObjectByPath {
    let baseURL = URL(string: "https://example.com/")!
    var session = MockURLSession()

    @Test("Success")
    func success() async throws {
        // Create a Hippo instance using a MockHTTPClient
        let responseBody = Data("SOMERESULT".utf8)
        
        session.requestHandlers.append({ request, requestBody in
            #expect(request.url == URL(string: "https://example.com/object/SOMEPATH")!)
            #expect(request.headerFields == .init())
            #expect(requestBody == nil)
            
            return (.init(status: .ok), responseBody)
        })
        
        let modelContainer = try ModelContainer(
            for: Hippo<ChaChaPoly>.makeSchema(),
            configurations: .init("testConfig", schema: Hippo<ChaChaPoly>.makeSchema(), isStoredInMemoryOnly: true)
        )
        
        let hippo = try Hippo<ChaChaPoly>(
            baseURL: baseURL,
            session: session,
            modelContainer: modelContainer
        )

        let path = "SOMEPATH"

        // Call a method to store the data
        await #expect(throws: Never.self) {
            let data = try await hippo.getObject(by: path)
            #expect(data == responseBody)
        }
    }

    @Test("Not found")
    func notFound() async throws {
        // Create a Hippo instance using a MockHTTPClient
        let responseBody = Data("Object not found".utf8)
        
        session.requestHandlers.append({request, requestBody in
            #expect(request.url == URL(string: "https://example.com/object/SOMEPATH")!)
            #expect(request.headerFields == .init())
            #expect(requestBody == nil)
            
            return (.init(status: .notFound), responseBody)
        })
        
        let modelContainer = try ModelContainer(
            for: Hippo<ChaChaPoly>.makeSchema(),
            configurations: .init("testConfig", schema: Hippo<ChaChaPoly>.makeSchema(), isStoredInMemoryOnly: true)
        )
        
        let hippo = try Hippo<ChaChaPoly>(
            baseURL: baseURL,
            session: session,
            modelContainer: modelContainer
        )

        let path = "SOMEPATH"

        // Call a method to store the data
        await #expect(throws: HippoClientError.self) {
            let data = try await hippo.getObject(by: path)
            #expect(data == responseBody)
        }
    }

    @Test("Unexpected error")
    func unexpectedError() async throws {
        // Create a Hippo instance using a MockHTTPClient
        let responseBody = Data()
        
        session.requestHandlers.append({request, requestBody in
            #expect(request.url == URL(string: "https://example.com/object/SOMEPATH")!)
            #expect(request.headerFields == .init())
            #expect(requestBody == nil)
            
            return (.init(status: .internalServerError), responseBody)
        })
        
        let modelContainer = try ModelContainer(
            for: Hippo<ChaChaPoly>.makeSchema(),
            configurations: .init("testConfig", schema: Hippo<ChaChaPoly>.makeSchema(), isStoredInMemoryOnly: true)
        )
        
        let hippo = try Hippo<ChaChaPoly>(
            baseURL: baseURL,
            session: session,
            modelContainer: modelContainer
        )

        let path = "SOMEPATH"

        // Call a method to store the data
        await #expect(throws: HippoClientError.self) {
            let data = try await hippo.getObject(by: path)
            #expect(data == responseBody)
        }
    }
}
