//
//  RequestUploadCredentials.swift
//  hippo-internal
//
//  Created by Nick Sloan on 9/17/24.
//

struct RequestUploadCredentials: Codable {
    enum CodingKeys: String, CodingKey {
        case clientReferenceOwner = "client_reference_owner"
        case clientReferenceID = "client_reference_id"
    }

    var clientReferenceOwner: String
    var clientReferenceID: String
}
