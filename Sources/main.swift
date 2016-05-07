//
//  main.swift
//  HangerSocket
//
//  Created by Yuki Takei on 5/5/16.
//
//

let t = Timer(tick: 1000)
t.start {
    let uri = URI(scheme: "http", host: "localhost", port: 8888, path: "/websocket")
    
    WebSocketClient(uri: uri) {
        do {
            let socket = try $0()
            socket.ping("hello".data)
            
            socket.onPong {
                print($0)
            }
            
        } catch {
            print(error)
        }
    }
}

var server = HTTPServer {
    let (request, stream) = try! $0()
    
    if let path = request.uri.path where path == "/websocket" {
        WebSocketServer(to: request, with: stream) {
            do {
                let socket = try $0()
                
                socket.onPing {
                    socket.pong("hello".data)
                    print($0)
                }
            } catch {
                let response = Response(status: .internalServerError, body: "\(error)")
                stream.send("\(response.description)\r\n".data)
                try! stream.close()
            }
        }
    }
}

try! server.bind(Address(host: "127.0.0.1", port: 8888))
try! server.listen()
