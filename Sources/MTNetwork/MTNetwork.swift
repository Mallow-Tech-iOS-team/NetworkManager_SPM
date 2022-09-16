//
//  MTNetwork.swift
//
//
//  Created by Dhanushkumar Kanagaraj on 14/09/22.
//

import Alamofire
import Foundation

public protocol MTNetworkProtocol: InterceptorProtocol { }

public class MTNetwork {
    var session: Session
    var requestEncoder: RequestEncoders
    public weak var delegate: MTNetworkProtocol?
    
    // MARK: - Initialisers
    
    public init(session: Session? = nil,
                delegate: MTNetworkProtocol,
                requestEncoder: RequestEncoders = RequestEncoders()) {
        self.delegate = delegate
        self.session = session ?? Session(interceptor: MTInterceptor(delegate: delegate),
                                           eventMonitors: [RequestEventMonitor()])
        self.requestEncoder = requestEncoder
    }
    
    public func request(_ router: Routable,
                 parameters: Parameters) -> DataRequest {
        let route = router.route
        // Using URLEncoding for GET request and JSONEncoding for other requests
        let encoder: ParameterEncoding = (route.method == .get) ? requestEncoder.urlEncoding : requestEncoder.jsonEncoding
        return session
            .request(route.path,
                     method: route.method,
                     parameters: parameters,
                     encoding: route.encoding ?? encoder,
                     headers: route.headers)
            .validate()
    }
    
    public func request(_ router: Routable,
                        parameters: some Encodable) -> DataRequest {
        let route = router.route
        // Using URLEncoder for GET request and JSONEncoder for other requests
        let encoder: ParameterEncoder = (route.method == .get) ? requestEncoder.urlEncoder : requestEncoder.jsonEncoder
        return session
            .request(route.path,
                     method: route.method,
                     parameters: parameters,
                     encoder: route.encoder ?? encoder,
                     headers: route.headers)
            .validate()
    }
}
