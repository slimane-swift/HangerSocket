# WS
WebSocket adapter for Skelton and Hanger

## Usage

### Server
```swift
import WS
import Skelton


var server = HTTPServer {
    let (request, stream) = try! $0()

    if let path = request.uri.path where path == "/websocket" {
        WebSocketServer(to: request, with: stream) {
            do {
                let socket = try $0()

                socket.onBinary {
                    print($0)
                }

                socket.onText {
                    print($0)
                }

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

## Licence

WS is released under the MIT license. See LICENSE for details.