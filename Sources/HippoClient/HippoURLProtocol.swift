//
//  HippoURLProtocol.swift
//  hippo-internal
//
//  Created by Nick Sloan on 9/16/24.
//
import Foundation
import CryptoKit
import SwiftData
import HTTPTypes

class HippoURLProtocol: URLProtocol {
    
    nonisolated(unsafe) static var hippo: Hippo? = nil

    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url, checkURL(url) else { return false }
        guard let hippo = Self.hippo else { return false }
        
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    class func checkURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme, scheme == Self.hippo?.urlScheme else { return false }
        
        return true
    }

    override func startLoading() {
        guard let url = request.url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            client?.urlProtocol(self, didFailWithError: HippoClientError.malformedURL)
            return
        }
        
        guard let hippo = Self.hippo else {
            client?.urlProtocol(self, didFailWithError: HippoClientError.malformedURL)
            return
        }
        
        let path = components.path
        
        Task {
            let data = try! await hippo.retrieveObject(by: url)
        
            guard let response = HTTPURLResponse(httpResponse: HTTPResponse(status: .ok), url: url) else {
                client?.urlProtocol(self, didFailWithError: HippoClientError.malformedURL)
                return
            }
            
            finishLoading(data: data, response: response)
        }
    }
    
    func finishLoading(data: Data, response: HTTPURLResponse) {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}
