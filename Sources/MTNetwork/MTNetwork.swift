//
//  MTNetwork.swift
//
//
//  Created by Dhanushkumar Kanagaraj on 14/09/22.
//

import Alamofire
import Foundation

open class MTNetwork {
    public private(set) var session: Session
    /// Holds different encoders required for the MTNetwork to encode the request
    public private(set) var requestEncoder: RequestEncoders
    /// Decoder required for the MTNetwork to decode the request
    public private(set) var decoder: JSONDecoder
    public private(set) var networkMonitor: NetworkMonitorProtocol
    public private(set) var interceptor: RequestInterceptor
    
    // MARK: - Initialisers
    
    public init(session: Session,
                requestEncoder: RequestEncoders = RequestEncoders(),
                decoder: JSONDecoder = JSONDecoder(),
                interceptor: RequestInterceptor,
                networkMonitor: some NetworkMonitorProtocol = NetworkMonitor.shared) {
        self.session = session
        self.requestEncoder = requestEncoder
        self.decoder = decoder
        self.interceptor = interceptor
        self.networkMonitor = networkMonitor
        
        networkMonitor.startMonitoring()
    }
    
    deinit {
        networkMonitor.stopMonitoring()
    }
    
    // MARK: - Custom Methods

    public func request(_ router: Routable,
                        parameters: Parameters? = nil,
                        interceptor: RequestInterceptor? = nil,
                        redirectHandler: RedirectHandler = .follow) -> DataRequest {
        let route = router.route
        // Using URLEncoding for GET request and JSONEncoding for other requests
        let encoder: ParameterEncoding = (route.method == .get) ? requestEncoder.urlEncoding : requestEncoder.jsonEncoding
        return session
            .request(route.path,
                     method: route.method,
                     parameters: parameters,
                     encoding: route.encoding ?? encoder,
                     headers: route.headers,
                     interceptor: interceptor ?? self.interceptor)
            .validate()
            .redirect(using: redirectHandler)
    }
    
    public func request(_ router: Routable,
                        parameters: some Encodable,
                        interceptor: RequestInterceptor? = nil,
                        redirectHandler: RedirectHandler = .follow) -> DataRequest {
        let route = router.route
        // Using URLEncoder for GET request and JSONEncoder for other requests
        let encoder: ParameterEncoder = (route.method == .get) ? requestEncoder.urlEncoder : requestEncoder.jsonEncoder
        return session
            .request(route.path,
                     method: route.method,
                     parameters: parameters,
                     encoder: route.encoder ?? encoder,
                     headers: route.headers,
                     interceptor: interceptor ?? self.interceptor)
            .validate()
            .redirect(using: redirectHandler)
    }
}
