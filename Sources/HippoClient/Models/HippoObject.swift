//
//  HippoObject.swift
//  hippo-internal
//
//  Created by Nick Sloan on 9/18/24.
//

import Foundation
import CryptoKit
import SwiftData

@Model
public class HippoObject {
    public var id: String?
    public var url: URL?
    public var contentType: String?
    
    @Attribute(.allowsCloudEncryption) var secret: Data?
    
    var key: SymmetricKey? {
        guard let secret else { return nil }
        
        return try? SymmetricKey(data: secret)
    }

    init(id: String, url: URL?, contentType: String, secret: SymmetricKey) {
        self.id = id
        self.url = url
        self.contentType = contentType
        self.secret = secret.withUnsafeBytes {
            Data($0)
        }
    }
}
