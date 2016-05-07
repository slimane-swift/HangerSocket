//
//  WebsocketClient.swift
//  HangerSocket
//
//  Created by Yuki Takei on 5/5/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

@_exported import Hanger
@_exported import Crypto

public struct WebSocketClient {
    
    public enum Error: ErrorProtocol {
        case NoRequest
        case ResponseNotWebsocket
    }
    
    let connection: ClientConnection
    
    public let uri: URI
    
    public let loop: Loop
    
    public init(loop: Loop = Loop.defaultLoop, uri: URI, onConnect: (Void throws -> WebSocket) -> Void) {
        self.uri = uri
        let request = Request(uri: uri)
        self.loop = loop
        self.connection = ClientConnection(loop: loop, uri: request.uri)
        connect(onConnect: onConnect)
    }
    
    private func connect(onConnect: (Void throws -> WebSocket) -> Void){
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
    
    private func onConnect(request: Request, response: Response, key: String, completion: (Void throws -> WebSocket) -> Void){
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