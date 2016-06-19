<<<<<<< HEAD
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
=======
# WebSocket

[![Swift][swift-badge]][swift-url]
[![Zewo][zewo-badge]][zewo-url]
[![Platform][platform-badge]][platform-url]
[![License][mit-badge]][mit-url]
[![Slack][slack-badge]][slack-url]
[![Travis][travis-badge]][travis-url]
[![Codebeat][codebeat-badge]][codebeat-url]

## Installation

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/Zewo/WebSocket.git", majorVersion: 0, minor: 8),
    ]
)
```

## Support

If you need any help you can join our [Slack](http://slack.zewo.io) and go to the **#help** channel. Or you can create a Github [issue](https://github.com/Zewo/Zewo/issues/new) in our main repository. When stating your issue be sure to add enough details, specify what module is causing the problem and reproduction steps.

## Community

[![Slack][slack-image]][slack-url]

The entire Zewo code base is licensed under MIT. By contributing to Zewo you are contributing to an open and engaged community of brilliant Swift programmers. Join us on [Slack](http://slack.zewo.io) to get to know us!

## License

This project is released under the MIT license. See [LICENSE](LICENSE) for details.

[swift-badge]: https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat
[swift-url]: https://swift.org
[zewo-badge]: https://img.shields.io/badge/Zewo-0.5-FF7565.svg?style=flat
[zewo-url]: http://zewo.io
[platform-badge]: https://img.shields.io/badge/Platforms-OS%20X%20--%20Linux-lightgray.svg?style=flat
[platform-url]: https://swift.org
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
[slack-image]: http://s13.postimg.org/ybwy92ktf/Slack.png
[slack-badge]: https://zewo-slackin.herokuapp.com/badge.svg
[slack-url]: http://slack.zewo.io
[travis-badge]: https://travis-ci.org/Zewo/WebSocket.svg?branch=master
[travis-url]: https://travis-ci.org/Zewo/WebSocket
[codebeat-badge]: https://codebeat.co/badges/7b271ac4-f447-45a5-8cd0-f0f4c2e57690
[codebeat-url]: https://codebeat.co/projects/github-com-zewo-websocket
>>>>>>> upstream/master
