//
//  WebsocketClient.swift
//  HangerSocket
//
//  Created by Yuki Takei on 5/5/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

// Client.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import HTTP
import HTTPParser
import AsyncHTTPSerializer

public enum ClientError: ErrorProtocol {
    case unsupportedScheme
    case hostRequired
    case responseNotWebsocket
}

public struct WebSocketClient {
    let connection: TCPClient
    
    public let uri: URI
    
    public let loop: Loop
    
    public init(loop: Loop = Loop.defaultLoop, uri: URI, onConnect: ((Void) throws -> WebSocket) -> Void) {
        self.uri = uri
        let request = Request(uri: uri)
        self.loop = loop
        self.connection = TCPClient(loop: loop, uri: request.uri)
        connect(onConnect: onConnect)
    }
    
    private func connect(onConnect: ((Void) throws -> WebSocket) -> Void){
        do {
            let key = try Base64.encode(Crypto.randomBytesSync(16))
            
            let headers: Headers = [
                "Connection": "Upgrade",
                "Upgrade": "websocket",
                "Sec-WebSocket-Version": "13",
                "Sec-WebSocket-Key": key,
            ]
            
            let request = Request(method: .get, uri: self.uri, headers: headers)
            
            // callback hell....
            try connection.open { getConnection in
                do {
                    let connection = try getConnection()
                    AsyncHTTPSerializer.RequestSerializer().serialize(request, to: connection)
                    let parser = ResponseParser()
                    connection.receive(upTo: 2048, timingOut: .never) {
                        do {
                            if let response = try parser.parse(try $0()) {
                                self.onConnect(request: request, response: response, key: key, completion: onConnect)
                            }
                        } catch {
                            onConnect {
                                throw error
                            }
                        }
                    }
                } catch {
                    onConnect {
                        throw error
                    }
                }
            }
        } catch {
            onConnect {
                throw error
            }
        }
    }
    
    private func onConnect(request: Request, response: Response, key: String, completion: ((Void) throws -> WebSocket) -> Void){
        guard response.status == .switchingProtocols && response.isWebSocket else {
            return completion {
                throw ClientError.responseNotWebsocket
            }
        }
        
        WebSocket.accept(key: key) { result in
            let accept = response.webSocketAccept
            completion {
                guard try accept == result() else {
                    throw ClientError.responseNotWebsocket
                }
                
                let socket = WebSocket(stream: self.connection, mode: .client)
                socket.start()
                return socket
            }
        }
    }
}


public extension Response {
    public var webSocketVersion: String? {
        return headers["Sec-Websocket-Version"]
    }

    public var webSocketKey: String? {
        return headers["Sec-Websocket-Key"]
    }

    public var webSocketAccept: String? {
        return headers["Sec-WebSocket-Accept"]
    }

    public var isWebSocket: Bool {
        return connection?.lowercased() == "upgrade" && upgrade?.lowercased() == "websocket"
    }
}