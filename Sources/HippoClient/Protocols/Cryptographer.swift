//
//  Cryptographer.swift
//  hippo-internal
//
//  Created by Nick Sloan on 10/23/24.
//
import Foundation
import CryptoKit

public protocol Cryptographer {
    func encrypt(_ data: Data, with secret: SymmetricKey) throws -> Data
    func decrypt(_ data: Data, with secret: SymmetricKey) throws -> Data
}
