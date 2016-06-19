//
//  WebSocketServer.swift
//  HangerSocket
//
//  Created by Yuki Takei on 5/5/16.
//
//

// Server.swift
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

public class WebSocketServer: AsyncResponder, AsyncMiddleware {
    
    private let didConnect: (WebSocket, Request) -> Void
    
    public init(_ didConnect: (WebSocket, Request) -> Void) {
        self.didConnect = didConnect
    }
    
    public func respond(to request: Request, chainingTo chain: AsyncResponder, result: ((Void) throws -> Response) -> Void) {
        guard request.isWebSocket && request.webSocketVersion == "13", let key = request.webSocketKey else {
            return chain.respond(to: request, result: result)
        }
        
        WebSocket.accept(key: key) { accept in
            do {
                guard let accept = try accept() else {
                    return result {
                        throw S4.ServerError.internalServerError
                    }
                }
                
                let headers: Headers = [
                    "Connection": "Upgrade",
                    "Upgrade": "websocket",
                    "Sec-WebSocket-Accept": accept
                ]
                
                let upgrade: (Request, AsyncStream) -> Void = { request, stream in
                    let socket = WebSocket(stream: stream, mode: .server)
                    self.didConnect(socket, request)
                    socket.start()
                }
                var response = Response(status: .switchingProtocols, headers: headers)
                response.didUpgradeAsync = upgrade
                result {
                    response
                }
            } catch {
                result {
                    throw error
                }
            }
        }
    }

    public func respond(to request: Request, result: ((Void) throws -> Response) -> Void) {
        let badRequest = BasicAsyncResponder { _, result in
            result {
                throw S4.ClientError.badRequest
            }
        }
        
        return respond(to: request, chainingTo: badRequest, result: result)
    }
}

public extension Message {
    
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
