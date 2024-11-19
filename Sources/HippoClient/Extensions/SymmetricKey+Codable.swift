//
//  SymmetricKey+Codable.swift
//  hippo-internal
//
//  Created by Nick Sloan on 10/8/24.
//
import Foundation
import CryptoKit

extension SymmetricKey: @retroactive Codable {
    enum CodingKeys: String, CodingKey {
        case data
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.decode(Data.self, forKey: .data)
        
        self.init(data: data)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.withUnsafeBytes{ Data($0) }, forKey: .data)
    }
}
