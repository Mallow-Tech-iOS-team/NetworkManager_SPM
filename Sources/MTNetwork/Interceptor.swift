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
    func cancelAllRequests()
}

public class MTInterceptor: RequestInterceptor {
    public static let defaultRetryStatusCodes: Set<Int> = []
    public static let defaultRetryLimit: Int = 2
    public static let defaultDelayTime: TimeInterval = 2
    public private(set) var isTokenRefreshing: Bool = false
    public let retryLimit: Int
    public let retryStatusCodes: Set<Int>
    public let delayTime: TimeInterval
    
    public weak var delegate: InterceptorProtocol?
    
    public init(retryLimit: Int = defaultRetryLimit,
                retryStatusCodes: Set<Int> = defaultRetryStatusCodes,
                delayTime: TimeInterval = defaultDelayTime,
                delegate: InterceptorProtocol) {
        self.retryLimit = retryLimit
        self.retryStatusCodes = retryStatusCodes
        self.delayTime = delayTime
        self.delegate = delegate
    }
    
    public func adapt(_ urlRequest: URLRequest,
                      for session: Session,
                      completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var request = urlRequest
        commonHeaders().forEach { request.headers.add($0) }
        
        completion(.success(request))
    }
    
    public func retry(_ request: Request,
                      for session: Session,
                      dueTo error: Error,
                      completion: @escaping (RetryResult) -> Void) async {
        // FIXME: - Ensure the await is not channeling the request serially
        let shouldRetry = await shouldRetry(request)
        completion(shouldRetry)
    }
}

extension MTInterceptor {
    func shouldRetry(_ request: Request) async -> RetryResult {
        guard let statusCode = request.response?.statusCode,
              request.retryCount < retryLimit else {
            return .doNotRetry
        }
        
        if let retry = RetryRequest(rawValue: statusCode) {
            return await handleRetryRequests(retry)
        } else if retryStatusCodes.contains(statusCode) {
            return .retry
        } else {
            return .doNotRetry
        }
    }
    
    func commonHeaders() -> HTTPHeaders {
        delegate?.commonHeaders() ?? []
    }
    
    func handleRetryRequests(_ retry: RetryRequest) async -> RetryResult {
        switch retry {
        case .tokenFailure:
            return await handleTokenFailure()
        }
    }
    
    func handleTokenFailure() async -> RetryResult {
        // FIXME: - Optimise the token refreshing logic
        guard !isTokenRefreshing else {
            return .retryWithDelay(delayTime)
        }
        isTokenRefreshing = true
        let refreshTokenStatus = await delegate?.refreshTokens()
        isTokenRefreshing = false
        switch refreshTokenStatus {
            case .success:
                return .retry
            case .failure:
                delegate?.cancelAllRequests()
                return .doNotRetry
            case .none:
                return .doNotRetry
        }
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
