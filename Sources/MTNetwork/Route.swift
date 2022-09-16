//
//  Route.swift
//  
//
//  Created by Dhanushkumar Kanagaraj on 14/09/22.
//

import Alamofire
import Foundation

/// Route holds the details of the API request
public struct Route {
    var path: URLConvertible
    var method: HTTPMethod
    var headers: HTTPHeaders?
    var encoding: ParameterEncoding?
    var encoder: ParameterEncoder?
    
    /// Create a Route using specified parameters
    /// - Parameters:
    ///   - path: path to request
    ///   - method: request method
    ///   - headers: request headers
    ///   - encoding: request encoding if required. URLEncoding / JSONEncoding will be used depending on the `method`
    ///   - encoder: request encoder if required. URLEncodedFormParameterEncoder / JSONParameterEncoder will be used depending on the `method`
    public init(path: URLConvertible,
         method: HTTPMethod,
         headers: HTTPHeaders? = nil,
         encoding: ParameterEncoding? = nil,
         encoder: ParameterEncoder? = nil) {
        self.path = path
        self.method = method
        self.headers = headers
        self.encoding = encoding
        self.encoder = encoder
    }
}

/// Create a Router from this protocol
public protocol Routable {
    var route: Route { get }
}
