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

@_exported import Hanger
@_exported import Crypto

public enum ClientError: ErrorProtocol {
    case wsSchemeRequired
    case hostRequired
}

public struct WebSocketClient {
    
    public enum Error: ErrorProtocol {
        case NoRequest
        case ResponseNotWebsocket
    }
    
    let connection: ClientConnection
    
    public let uri: URI
    
    public let loop: Loop
    
    public init(loop: Loop = Loop.defaultLoop, uri: URI, onConnect: ((Void) throws -> WebSocket) -> Void) {
        self.uri = uri
        let request = Request(uri: uri)
        self.loop = loop
        self.connection = ClientConnection(loop: loop, uri: request.uri)
        connect(onConnect: onConnect)
    }
    
    private func connect(onConnect: ((Void) throws -> WebSocket) -> Void){
        do {
            let key = try Base64.encode(Crypto.randomBytesSync(16).bufferd)
            
            let headers: Headers = [
                "Connection": "Upgrade",
                "Upgrade": "websocket",
                "Sec-WebSocket-Version": "13",
                "Sec-WebSocket-Key": [key],
            ]
            
            var request = Request(method: .get, uri: self.uri, headers: headers)
            
            // callback hell....
            try connection.open { f in
                do {
                    try self.connection.send(request.serialize())
                    
                    let parser = ResponseParser()
                    
                    self.connection.receive {
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
                throw Error.ResponseNotWebsocket
            }
        }
        
        WebSocket.accept(key: key) { f in
            let accept = response.webSocketAccept
            completion {
                guard try accept == f() else {
                    throw Error.ResponseNotWebsocket
                }
                
                let socket = WebSocket(stream: self.connection, mode: .Client, request: request, response: response)
                socket.receiveStart()
                return socket
            }
        }
    }
}
