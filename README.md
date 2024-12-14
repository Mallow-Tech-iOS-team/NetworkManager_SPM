## NetworkManager\_SPM

**NetworkManager\_SPM** is a package used to manage network calls that use **Alamofire** as its core.

### Features

*   [x] Routes _(Used to manage the routes)_
*   [ ] Network Reachability
*   [x] Async / Await _(Alamofire supported)_
*   [x] Combine _(Alamofire supported)_
*   [x] Handles Token refresh _(with Alamofire's Interceptor)_

### _Usage:_

#### _Route_ 

```swift
enum MyRouter: Routable {
    case route1
    
    var route: Route {
        switch self {
        case .route1:
            return Route(path: "https://domain.com/path",
                         method: .post)    
        }
    }
}
```

#### Network Setup

```swift

class MyNetwork {
    static let shared: MTNetwork = MTNetwork(session: Session(configuration: .primaryConfiguration,
                                                              interceptor: MTInterceptor(delegate: MyInterceptor()),
                                                              eventMonitors: [RequestEventMonitor()]),
                                             requestEncoder: RequestEncoders(),
                                             decoder: .primaryDecoder)
                                             
    /// Other Related Logics
}

class MyInterceptor: InterceptorProtocol {
    func commonHeaders() -> HTTPHeaders {
        // MARK: - Handle the common Headers for Every Request or Specific domain
        return []
    }
    
    func refreshTokens() async -> MTInterceptor.RefreshTokenStatus {
        // MARK: - Handle the Refresh Token Network Calls here
        return .success
    }
}

// MARK: - Since most of the app use same configuration, Configure like the below
extension URLSessionConfiguration {
    static var primaryConfiguration: URLSessionConfiguration {
        let configuration: URLSessionConfiguration = .default
        configuration.timeoutIntervalForRequest = 300
        return configuration
    }
}

// MARK: - Since most of the app use same Decoder, Configure like the below
extension JSONDecoder {
    static var primaryDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        decoder.dateDecodingStrategy = .formatted(formatter)
        
        return decoder
    }
}
```

> Currently Under Development, **⛔️ DO NOT USE FOR PRODUCTION ⛔️**
