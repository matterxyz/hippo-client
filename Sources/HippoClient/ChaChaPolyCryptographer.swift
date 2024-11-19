//
//  ChaChaPolyCryptographer.swift
//  hippo-internal
//
//  Created by Nick Sloan on 10/23/24.
//
import Foundation
import CryptoKit

public struct ChaChaPolyCryptographer: Cryptographer {
    public init () {}
    
    public func encrypt(_ data: Data, with secret: SymmetricKey) throws -> Data {
        let sealedBox = try ChaChaPoly.seal(data, using: secret, nonce: nil)
        return sealedBox.combined
    }
    
    public func decrypt(_ data: Data, with secret: SymmetricKey) throws -> Data {
        let sealedBox = try ChaChaPoly.SealedBox(combined: data)
        let data = try ChaChaPoly.open(sealedBox, using: secret)
        return data
    }
}
