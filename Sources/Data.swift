//
//  Data.swift
//  HangerSocket
//
//  Created by Yuki Takei on 5/5/16.
//
//

extension Buffer {
    internal var data: Data {
        return Data(self.bytes)
    }
}

extension Data {
    internal var signedBytes: [Int8] {
        return self.bytes.map { Int8(bitPattern: $0) }
    }
    
    internal var bufferd: Buffer {
        return Buffer(bytes: self.bytes)
    }
}
