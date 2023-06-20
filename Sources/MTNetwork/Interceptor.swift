//
//  Interceptor.swift
//  
//
//  Created by Dhanushkumar Kanagaraj on 16/09/22.
//

import Alamofire
import Foundation

public protocol InterceptorProtocol: AnyObject {
    var tokenRefreshHttpsCodes: Set<Int> { get }
    
    func commonHeaders() -> HTTPHeaders
    /// Handle the success logic and failure logic for token handling inside this methods
    /// (Like storing tokens on keychain during success or Logout during the failure)
    /// - Returns: return the result type
    func refreshTokens() async -> MTInterceptor.RefreshTokenStatus
    func cancelAllRequests()
}

public class MTInterceptor: RequestInterceptor {
    public private(set) var isTokenRefreshing: Bool = false
    public let retryLimit: Int
    public let retryStatusCodes: Set<Int>
    public let delayTime: TimeInterval
    
    public var delegate: InterceptorProtocol
    
    // MARK: - Initialisers
    
    public init(retryLimit: Int = 3, // Default retry limit is 3
                retryStatusCodes: Set<Int> = [], // Default retry status code is []
                delayTime: TimeInterval = 2, // Default retry delay time is 2
                delegate: InterceptorProtocol) {
        self.retryLimit = retryLimit
        self.retryStatusCodes = retryStatusCodes
        self.delayTime = delayTime
        self.delegate = delegate
    }
    
    // MARK: - Inherited Methods
    
    public func adapt(_ urlRequest: URLRequest,
                      for session: Session,
                      completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var request = urlRequest
        
        // Add common headers and over-write common headers keys with Current Header Keys if Repeated
        var headers = commonHeaders()
        request.headers.forEach { headers.add($0) }
        request.headers = headers
        
        completion(.success(request))
    }
    
    public func retry(_ request: Request,
                      for session: Session,
                      dueTo error: Error,
                      completion: @escaping (RetryResult) -> Void) {
        // Some of the logics in shouldRetry->handleRetryRequests->handleTokenFailure->delegate.refreshTokens
        // is expected to be executed in main thread
        Task { @MainActor in
            let shouldRetry = await shouldRetry(request)
            completion(shouldRetry)
        }
    }
}

extension MTInterceptor {
    // MARK: - Custom Methods
    func shouldRetry(_ request: Request) async -> RetryResult {
        guard let statusCode = request.response?.statusCode,
              request.retryCount < retryLimit else {
            return .doNotRetry
        }
        
        if delegate.tokenRefreshHttpsCodes.contains(statusCode) {
            return await handleTokenFailure()
        } else if retryStatusCodes.contains(statusCode) {
            return .retry
        } else {
            return .doNotRetry
        }
    }
    
    func commonHeaders() -> HTTPHeaders {
        delegate.commonHeaders()
    }
    
    @MainActor
    func handleTokenFailure() async -> RetryResult {
        // FIXME: - Optimise the token refreshing logic
        guard !isTokenRefreshing else {
            return .retryWithDelay(delayTime)
        }
        isTokenRefreshing = true
        let refreshTokenStatus = await delegate.refreshTokens()
        isTokenRefreshing = false
        switch refreshTokenStatus {
            case .success:
                return .retry
            case .failure:
                delegate.cancelAllRequests()
                return .doNotRetry
        }
    }
}

extension MTInterceptor {
    // MARK: - Enumerations
    public enum RefreshTokenStatus {
        case success
        case failure
    }
}

// RetryPolicy - Used to retry request, they have added some standard retrying conditions. Use it if necessary
