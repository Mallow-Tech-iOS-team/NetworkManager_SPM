//
//  Interceptor.swift
//  
//
//  Created by Dhanushkumar Kanagaraj on 16/09/22.
//

import Alamofire
import Foundation

public protocol InterceptorProtocol: AnyObject {
    func commonHeaders() -> HTTPHeaders
    /// Handle the success logic and failure logic for token handling inside this methods (Like storing tokens on keychain during success or Logout during the failure)
    /// - Returns: return the result type
    func refreshTokens() async -> MTInterceptor.RefreshTokenStatus
}

public class MTInterceptor: RequestInterceptor {
    public static let defaultRetryStatusCodes: Set<Int> = []
    public static let defaultRetryLimit: Int = 2
    public let retryLimit: Int
    public let retryStatusCodes: Set<Int>
    
    public weak var delegate: InterceptorProtocol?
    
    public init(retryLimit: Int = defaultRetryLimit,
                retryStatusCodes: Set<Int> = defaultRetryStatusCodes,
                delegate: InterceptorProtocol) {
        self.retryLimit = retryLimit
        self.retryStatusCodes = retryStatusCodes
        self.delegate = delegate
    }
    
    public func adapt(_ urlRequest: URLRequest,
                      for session: Session,
                      completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var request = urlRequest
        request.headers = commonHeaders() ?? []
        
        completion(.success(request))
    }
    
    public func retry(_ request: Request,
                      for session: Session,
                      dueTo error: Error,
                      completion: @escaping (RetryResult) -> Void) {
        Task {
            await shouldRetry(request) ? completion(.retry) : completion(.doNotRetry)
        }
    }
    
    func shouldRetry(_ request: Request) async -> Bool {
        guard let statusCode = request.response?.statusCode,
              request.retryCount < retryLimit else {
            return false
        }
        
        if let retry = RetryRequest(rawValue: statusCode) {
            switch retry {
                case .tokenFailure:
                    return await delegate?.refreshTokens() == .success ? true : false
            }
        } else if retryStatusCodes.contains(statusCode) {
            return true
        } else {
            return false
        }
    }
    
    func commonHeaders() -> HTTPHeaders? {
        delegate?.commonHeaders()
    }
}

extension MTInterceptor {
    public enum RefreshTokenStatus {
        case success
        case failure
    }
    
    public enum RetryRequest: Int, CaseIterable {
        case tokenFailure = 401
    }
}

// RetryPolicy - Used to retry request, they have added some standard retrying conditions. Use it if necessary
