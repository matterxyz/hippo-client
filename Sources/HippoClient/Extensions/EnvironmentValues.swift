//
//  EnvironmentValues.swift
//  hippo-internal
//
//  Created by Nick Sloan on 10/21/24.
//
import CryptoKit
import SwiftUI

public extension EnvironmentValues {
    @Entry var hippo: Hippo? = nil
}

public extension View {
    public func hippo(_ hippo: Hippo?) -> some View {
        environment(\.hippo, hippo)
    }
}
