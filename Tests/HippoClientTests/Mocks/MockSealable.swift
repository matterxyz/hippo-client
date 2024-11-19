//
//  MockCipher.swift
//  hippo-internal
//
//  Created by Nick Sloan on 10/1/24.
//
import Foundation
import CryptoKit
import HippoClient

struct MockSealable: Sealable {
    typealias Nonce = Sequence
    
    public struct SealedBox: SealedBoxType {
        let data: any DataProtocol
        let key: SymmetricKey
        
        var combined: Data {
            Data("ENCRYPTED#".utf8) + data
        }
        
        public init<D: DataProtocol>(data: D, key: SymmetricKey) throws {
            self.data = data
            self.key = key
        }
    }
    
    static func seal<Plaintext>(_ message: Plaintext, using key: SymmetricKey, nonce: (any Nonce)?) throws -> SealedBox where Plaintext : DataProtocol {
        return try SealedBox(data: message, key: key)
    }
}
