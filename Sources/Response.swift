//
//  Response.swift
//  HLSServer
//
//  Created by Yuki Takei on 6/19/16.
//
//

extension Response {
    public typealias DidUpgradeAsync = (Request, AsyncStream) -> Void
    
    public var didUpgradeAsync: DidUpgradeAsync? {
        get {
            return storage["response-connection-upgrade"] as? DidUpgradeAsync
        }
        
        set(didUpgrade) {
            storage["response-connection-upgrade"] = didUpgrade
        }
    }
}