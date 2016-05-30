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

public class WebSocketServer {
    
    enum Error: ErrorProtocol {
        case InvalidHeaderValue(message: String)
    }

    public init(to request: Request, with stream: AsyncStream, onConnect: ((Void) throws -> WebSocket) -> Void){
        guard request.isWebSocket && request.webSocketVersion == "13", let key = request.webSocketKey else {
            onConnect {
                throw Error.InvalidHeaderValue(message: "The request has unsatisfied WebSocket headers.")
            }
            return
        }
        
        WebSocket.accept(key: key) {
            do {
                guard let accept = try $0() else {
                    return onConnect {
                        throw Error.InvalidHeaderValue(message: "The requested Sec-Websocket-Key is invaid format.")
                    }
                }
                
                let headers: Headers = [
                    "Connection": "Upgrade",
                    "Upgrade": "websocket",
                    "Sec-WebSocket-Accept": Header([accept])
                ]
                
                let response = Response(status: .switchingProtocols, headers: headers)
                stream.send(response.description+"\r\n".data) { f in
                    onConnect {
                        try f()
                        let socket = WebSocket(stream: stream, mode: .Server, request: request, response: response)
                        socket.receiveStart()
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
        return headers["Sec-Websocket-Version"].first
    }
    
    public var webSocketKey: String? {
        return headers["Sec-Websocket-Key"].first
    }
    
    public var webSocketAccept: String? {
        return headers["Sec-WebSocket-Accept"].first
    }
    
    public var isWebSocket: Bool {
        return connection.first?.lowercased() == "upgrade" && upgrade.first?.lowercased() == "websocket"
    }
    
}
