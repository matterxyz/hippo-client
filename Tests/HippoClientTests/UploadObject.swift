//
//  UploadObject.swift
//  hippo-internal
//
//  Created by Nick Sloan on 9/17/24.
//
import Testing
import Foundation
import HTTPTypes
import SwiftData
import CryptoKit

@testable import HippoClient

struct RequestKey: Hashable {
    var request: HTTPRequest
    var body: Data
}

//@Suite("Upload object", .serialized)
//struct UploadObject {
//    
//    var session = MockURLSession()
//    
//    let baseURL = URL(string: "https://example.com/")!
//
//    @Test("Success")
//    func success() async throws {
//        let credentialResponse = ResponseUploadCredentials(
//            futureURL: URL(string: "https://example.com/path")!,
//            futurePath: "path",
//            putURL: URL(string: "https://example.com/put/path")!,
//            objectSecret: "SOMESECRET"
//        )
//        
//        let credentialRequestBody = Data("{\"client_reference_id\":\"SOMEREFERENCE\",\"client_reference_owner\":\"SOMEOWNER\"}".utf8)
//
//        // Create a Hippo instance using a MockHTTPClient
//        let responseBody = try JSONEncoder().encode(credentialResponse)
//        
//        session.requestHandlers.append({ request, data in
//            #expect(request.url == URL(string: "https://example.com/object")!)
//            #expect(request.headerFields == .init())
//            
//            let data = try #require(data)
//            #expect(data == credentialRequestBody)
//            
//            return (.init(status: .ok), responseBody)
//        })
//        
//        session.requestHandlers.append({ request, data in
//            #expect(request.url == credentialResponse.putURL)
//            #expect(request.headerFields == .init())
//            let data = try #require(data)
//            #expect(data == Data("ENCRYPTED#".utf8))
//            
//            return (.init(status: .ok), responseBody)
//        })
//        
//        let modelContainer = try ModelContainer(
//            for: Hippo<ChaChaPoly>.makeSchema(),
//            configurations: .init("testConfig", schema: Hippo<ChaChaPoly>.makeSchema(), isStoredInMemoryOnly: true)
//        )
//        
//        let hippo = try Hippo(
//            baseURL: baseURL,
//            session: session,
//            sealable: MockSealable.self,
//            modelContainer: modelContainer
//        )
//
//        let clientOwner = "SOMEOWNER"
//        let clientReference = "SOMEREFERENCE"
//
//        // Call a method to store the data
//        await #expect(throws: Never.self) {
//            try await hippo.uploadObject(by: clientOwner, for: clientReference, with: Data())
//        }
//    }
//}
