//
//  ResponseUploadCredentials.swift
//  hippo-internal
//
//  Created by Nick Sloan on 9/18/24.
//
import Foundation

struct ResponseUploadCredentials: Codable {
    enum CodingKeys: String, CodingKey {
        case futureURL = "future_url"
        case futurePath = "future_path"
        case putURL = "put_url"
        case objectSecret = "object_secret"
    }

    var futureURL: URL
    var futurePath: String
    var putURL: URL
    var objectSecret: String
}
