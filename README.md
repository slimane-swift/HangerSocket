# WS
WebSocket adapter for Skelton and Hanger

## Usage

### Server
```swift
import WS
import Skelton


let wsServer = WebSocketServer { socket, request in
    socket.onText { text in
        print(text)
    }
}

let server = Skelton() { load in
    do {
        let (request, stream) = try load()
        
        if request.isWebSocket {
            let dummyResponder = BasicAsyncResponder { request, result in
                result {
                    Response()
                }
            }
            
            return wsServer.respond(to: request, chainingTo: dummyResponder) { getResponse in
                do {
                    let response = try getResponse()
                    
                    AsyncHTTPSerializer.ResponseSerializer().serialize(request, to: stream) { _ in
                        response.didUpgradeAsync?(request, stream)
                    }
                } catch {
                    let response = Response(status: .internalServerError)
                    AsyncHTTPSerializer.ResponseSerializer().serialize(request, to: stream)
                }
            }
        }
        
    } catch ClosableError.alreadyClosed {
        
    } catch {
        print(error)
    }
}

try! server.bind(port: 8888)
try! server.listen()
```

### Client
```swift
import WS

let uri = URI(scheme: "http", host: "localhost", port: 8888, path: "/websocket")

WebSocketClient(uri: uri) {
    do {
        let socket = try $0()

        socket.ping("hello".data)

        socket.send("hello".data)

        socket.send("hello")

        socket.onPong {
            print($0)
        }
    } catch {
        print(error)
    }
}
```

## License

WS is released under the MIT license. See LICENSE for details.
