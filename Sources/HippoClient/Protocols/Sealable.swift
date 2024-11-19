//
//  Sealable.swift
//  hippo-internal
//
//  Created by Nick Sloan on 10/1/24.
//

import Foundation
import CryptoKit

public protocol Sealable where SealedBox : SealedBoxType {
    associatedtype Nonce
    associatedtype SealedBox
    
    static func seal<Plaintext>(
        _ message: Plaintext,
        using key: SymmetricKey,
        nonce: Nonce?
    ) throws -> SealedBox where Plaintext : DataProtocol
}

public protocol SealedBoxType {
    var combined: Data { get }
}

extension ChaChaPoly: Sealable {}
extension ChaChaPoly.SealedBox: SealedBoxType {}
