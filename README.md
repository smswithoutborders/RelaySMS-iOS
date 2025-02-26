## grpc configurations
### macOS
> https://levelup.gitconnected.com/swift-grpc-577ce1a4d1b7

```bash
brew install swift-protobuf grpc-swift

protoc --swift_out=. $1
protoc --grpc-swift_out=. $1
```
