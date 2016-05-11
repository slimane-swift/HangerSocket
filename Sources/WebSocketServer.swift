//
//  WebSocketServer.swift
//  HangerSocket
//
//  Created by Yuki Takei on 5/5/16.
//
//

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