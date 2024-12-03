//
//  HippoClient.swift
//  hippo-internal
//
//  Created by Nick Sloan on 9/12/24.
//
import Foundation
import HTTPTypes
import CryptoKit
import SwiftData
import HTTPTypesFoundation

public enum HippoClientError: Error {
    case unexpectedError
    case noSuchObject
    case invalidURL
    case malformedURL
    case invalidObjectRecord
    case serverRetrievalFailure
    case noDataRetrieved
    case requestError
    case responseError
    case missingClientOwnerID
}

/// A high-level interface for the Hippo service
public struct Hippo: Sendable {
    /// the URL that service requests will be sent to
    let baseURL: URL
    /// A Sealable type that is used for encrypting and decrypting data
    let cryptographer: Cryptographer
    /// an HTTPReqestable for executing the requests
    let session: HTTPRequestable
    let dataLocation: URL
    public var clientOwnerID: String?
    let urlScheme: String
    
    let modelContainer: ModelContainer

    public static func makeModelConfiguration(
        groupContainer: ModelConfiguration.GroupContainer,
        cloudKitContainerID: String
    ) -> ModelConfiguration {
        let modelConfiguration = ModelConfiguration(
            "hippo",
            schema: Self.makeSchema(),
            groupContainer: groupContainer,
            cloudKitDatabase: .private(cloudKitContainerID)
        )
        
        return modelConfiguration
    }
    
    /// Create a Swift Data schema for Hippo that can be used to initialize the
    /// Swift Data ModelContainer
    /// - Returns: A Swift Data schema containing the entities used by Hippo
    public static func makeSchema() -> Schema {
        Schema([HippoObject.self])
    }
    
    public init(
        baseURL: URL,
        session: some HTTPRequestable = URLSession.shared,
        clientOwnerID: String?,
        cryptographer: Cryptographer = ChaChaPolyCryptographer(),
        dataLocation: URL? = nil,
        modelContainer: ModelContainer,
        urlScheme: String = "hippo"
    ) throws {
        self.baseURL = baseURL
        self.session = session
        self.clientOwnerID = clientOwnerID
        self.cryptographer = cryptographer
        self.modelContainer = modelContainer
        self.urlScheme = urlScheme
        
        if let dataLocation {
            self.dataLocation = dataLocation
        } else {
            let baseURL = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            
            self.dataLocation = baseURL.appending(path: "hippo-objects")
        }
    }
    
    /// Store an object in Hippo. This is a synchronous method
    /// - Parameter data: The data to be saved
    /// - Returns: A URL reference for the saved object
    public func saveObject(_ data: Data, contentType: String) throws -> URL {
        let fileManager = FileManager.default
        // Save the object to disk
        let documents = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        try fileManager.createDirectory(at: dataLocation, withIntermediateDirectories: true)
        
        // Create the Swift Data record to store a reference to the object
        let id = UUID()
        let idString = id.uuidString
        let fileURL = dataLocation.appending(path: idString)
        
        let secret = SymmetricKey(size: .bits256)
        
        let object = HippoObject(id: idString, url: fileURL, contentType: contentType, secret: secret)
        
        let modelContext = ModelContext(modelContainer)
        modelContext.insert(object)
        try modelContext.save()
        
        let encryptedData = try encrypt(data, key: secret)
        try encryptedData.write(to: fileURL)
        
        // Return the ID
        var components = URLComponents()
        components.scheme = urlScheme
        components.path.append(idString)
        
        guard let url = components.url else { throw HippoClientError.malformedURL }
        
        if Task.isCancelled {
            return url
        }
        
        Task {
            try await uploadObject(for: idString)
        }
        
        return url
    }
    
    /// Register a URLProtocol to handle Hippo URLs
    /// - Parameter session: the URLSession to register the  URLProtocol for
    public func registerProtocol() {
        HippoURLProtocol.hippo = self
        URLProtocol.registerClass(HippoURLProtocol.self)
    }
    
    /// Check for objects that have not been uploaded yet and upload them
    public func syncLocalObjects() async throws {
        let fetchDescriptor = FetchDescriptor<HippoObject>(
            predicate: #Predicate { $0.url?.scheme == "file" }
        )
        
        let modelContext = ModelContext(modelContainer)
        let results = try modelContext.fetch(fetchDescriptor)
        
        for object in results {
            guard let id = object.id else {
                // LOG THE ERROR
                continue
            }
            
            try await uploadObject(for: id)
        }
    }
    
    /// Get count of all objects and local objects stored by Hippo
    /// - Returns: A tuple of all memories and local memories
    public func getObjectCounts() throws -> (all: Int, local: Int) {
        let fetchDescriptor = FetchDescriptor<HippoObject>()
        
        let modelContext = ModelContext(modelContainer)
        let results = try modelContext.fetch(fetchDescriptor)
        
        let allObjectCount = results.count
        
        let localObjectCount = results.filter {
            $0.url?.scheme == "file"
        }.count
        
        return (all: allObjectCount, local: localObjectCount)
    }
    
    func getObjectRecord(by id: String) throws -> HippoObject {
        let fetchDescriptor = FetchDescriptor<HippoObject>(
            predicate: #Predicate { $0.id == id }
        )
        
        let modelContext = ModelContext(modelContainer)
        let results = try modelContext.fetch(fetchDescriptor)
        
        guard let object = results.first else {
            throw HippoClientError.noSuchObject
        }
        
        return object
    }
    
    public func retrieveObject(by url: URL) async throws -> Data {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw HippoClientError.malformedURL
        }
        
        let path = components.path
        
        let object = try getObjectRecord(by: path)
        
        guard let dataURL = object.url else {
            throw HippoClientError.invalidObjectRecord
        }
        
        var data: Data? = nil
        
        if dataURL.scheme == "file" {
            data = try Data(contentsOf: dataURL)
        } else if dataURL.scheme == "https" {
            let request = HTTPRequest(method: .get, url: dataURL)
            
            var response: HTTPResponse
            
           (data, response) = try await URLSession.shared.data(for: request)
            
            if response.status.kind != .successful {
                throw HippoClientError.serverRetrievalFailure
            }
        }
        
        guard let data else {
            throw HippoClientError.noDataRetrieved
        }
        
        guard let secret = object.key else {
            throw HippoClientError.invalidObjectRecord
        }
        
        let decryptedData = try decrypt(data, key: secret)
        
        return decryptedData
    }

    /// Get an object by its client reference
    /// - Parameters:
    ///   - clientID: An identifier for the object itself that is unique to the client
    /// - Returns: Decrypted object data
    public func getObject(for clientID: String) async throws -> Data {
        var url = baseURL.appending(path: "object")
        guard let clientOwnerID else { throw HippoClientError.missingClientOwnerID }

        url.append(queryItems: [
            .init(name: "client_reference_owner", value: clientOwnerID),
            .init(name: "client_reference_id", value: clientID)
        ])

        var body: Data?
        var response: HTTPResponse?
        let request = HTTPRequest(method: .get, url: url, headerFields: .init())

        do {
            (body, response) = try await session.data(for: request)
        } catch {
            throw HippoClientError.serverRetrievalFailure
        }

        guard let body, let response else {
            throw HippoClientError.unexpectedError
        }

        if response.status.kind == .serverError {
            throw HippoClientError.serverRetrievalFailure
        }

        if response.status == .notFound {
            throw HippoClientError.noSuchObject
        }

        return Data()
    }
    
    /// Get an object by it's path
    /// - Parameter path: The server-side identifier for an object
    /// - Returns: Decrypted object data
    public func getObject(by path: String) async throws -> Data {
        let url = baseURL.appending(components: "object", path)

        var body: Data?
        var response: HTTPResponse?
        let request = HTTPRequest(method: .get, url: url, headerFields: .init())

        do {
            (body, response) = try await session.data(for: request)
        } catch {
            throw HippoClientError.serverRetrievalFailure
        }

        guard let body, let response else {
            throw HippoClientError.unexpectedError
        }

        if response.status.kind == .serverError {
            throw HippoClientError.serverRetrievalFailure
        }

        if response.status == .notFound {
            throw HippoClientError.noSuchObject
        }

        return Data()
    }

    private func uploadObject(
        for clientID: String
    ) async throws {
        let credentials = try await getUploadCredentials(
            clientID: clientID
        )
        
        let object = try getObjectRecord(by: clientID)
        
        guard let url = object.url else { throw HippoClientError.invalidObjectRecord }

        try await uploadData(url, for: credentials)
        
        object.url = credentials.futureURL
        
        let modelContext = ModelContext(modelContainer)
        modelContext.insert(object)
        try modelContext.save()
        
        try deleteTemporaryData(url)
    }
    
    private func deleteTemporaryData(_ url: URL) throws {
        let fm = FileManager.default
        
        try fm.removeItem(at: url)
    }

    private func getUploadCredentials(clientID: String) async throws -> ResponseUploadCredentials {
        let url = baseURL.appending(path: "object")

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        guard let clientOwnerID else { throw HippoClientError.missingClientOwnerID }

        let requestUploadCredentials = RequestUploadCredentials(
            clientReferenceOwner: clientOwnerID,
            clientReferenceID: clientID
        )

        var body: Data?
        var response: HTTPResponse?
        
        let request = HTTPRequest(method: .post, url: url, headerFields: .init())

        do {
            (body, response) = try await session.upload(for: request, from: encoder.encode(requestUploadCredentials))
        }

        guard let body, let response else {
            throw HippoClientError.unexpectedError
        }

        if response.status.kind == .serverError {
            throw HippoClientError.unexpectedError
        }

        if response.status == .notFound {
            throw HippoClientError.noSuchObject
        }

        let decoder = JSONDecoder()

        let output = try decoder.decode(
            ResponseUploadCredentials.self,
            from: body
        )

        return output
    }

    private func uploadData(
        _ file: URL,
        for credentials: ResponseUploadCredentials
    ) async throws {
        var body: Data?
        var response: HTTPResponse?
        let request = HTTPRequest(method: .put, url: credentials.putURL, headerFields: .init())

        (body, response) = try await session.upload(for: request, fromFile: file)

        guard let body, let response else {
            throw HippoClientError.unexpectedError
        }

        if response.status.kind == .serverError {
            throw HippoClientError.unexpectedError
        }

        if response.status == .notFound {
            throw HippoClientError.noSuchObject
        }
    }
    
    private func encrypt(_ data: Data, key: SymmetricKey) throws -> Data {
        try cryptographer.encrypt(data, with: key)
    }

    private func decrypt(_ data: Data, key: SymmetricKey) throws -> Data {
        try cryptographer.decrypt(data, with: key)
    }
}
