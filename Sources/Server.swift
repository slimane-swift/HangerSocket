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


import AsyncHTTPSerializer

public enum ServerError: Error {
    case invalidHeaderValue(message: String)
}

public class WebSocketServer {

    public init(request: Request, to stream: AsyncStream, onConnect: @escaping ((Void) throws -> WebSocket) -> Void){
        guard request.isWebSocket && request.webSocketVersion == "13", let key = request.webSocketKey else {
            onConnect {
                throw ServerError.invalidHeaderValue(message: "The request has unsatisfied WebSocket headers.")
            }
            return
        }
        
        WebSocket.accept(key: key) {
            do {
                guard let accept = try $0() else {
                    return onConnect {
                        throw ServerError.invalidHeaderValue(message: "The requested Sec-Websocket-Key is invaid format.")
                    }
                }
                
                let headers: Headers = [
                    "Connection": "Upgrade",
                    "Upgrade": "websocket",
                    "Sec-WebSocket-Accept": accept
                ]
                
                let response = Response(status: .switchingProtocols, headers: headers)
                AsyncHTTPSerializer.ResponseSerializer(stream: stream).serialize(response) { result in
                    onConnect {
                        try result()
                        let socket = WebSocket(stream: stream, mode: .server)
                        socket.start()
                        return socket
                    }
                }
            } catch {
                onConnect {
                    throw error
                }
            }
        }
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
