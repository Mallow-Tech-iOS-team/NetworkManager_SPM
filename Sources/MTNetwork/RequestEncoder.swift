//
//  RequestEncoder.swift
//  
//
//  Created by Dhanushkumar Kanagaraj on 15/09/22.
//

import Alamofire

/// Holds different encoder types used in Network under single hood
public class RequestEncoders {
    let urlEncoding: URLEncoding
    let urlEncoder: URLEncodedFormParameterEncoder
    let jsonEncoding: JSONEncoding
    let jsonEncoder: JSONParameterEncoder
    
    public init(urlEncoding: URLEncoding = .default,
                urlEncoder: URLEncodedFormParameterEncoder = .default,
                jsonEncoding: JSONEncoding = .default,
                jsonEncoder: JSONParameterEncoder = .default) {
        self.urlEncoding = urlEncoding
        self.urlEncoder = urlEncoder
        self.jsonEncoding = jsonEncoding
        self.jsonEncoder = jsonEncoder
    }
}
