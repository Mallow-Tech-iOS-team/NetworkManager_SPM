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
    public let retryHTTPStatusCodes: Set<Int>
    public let retryURLErrorCodes: Set<URLError.Code>
    public let retryHTTPMethods: Set<HTTPMethod>
    public let delayTime: TimeInterval
    
    public var delegate: InterceptorProtocol
    
    // MARK: - Initialisers
    
    public init(retryLimit: Int = 3, // Default retry limit is 3
                retryHTTPStatusCodes: Set<Int> = RetryPolicy.defaultRetryableHTTPStatusCodes,
                retryURLErrorCodes: Set<URLError.Code> = RetryPolicy.defaultRetryableURLErrorCodes,
                retryHTTPMethods: Set<HTTPMethod> = RetryPolicy.defaultRetryableHTTPMethods,
                delayTime: TimeInterval = 2, // Default retry delay time is 2
                delegate: InterceptorProtocol) {
        self.retryLimit = retryLimit
        self.retryHTTPStatusCodes = retryHTTPStatusCodes
        self.retryURLErrorCodes = retryURLErrorCodes
        self.retryHTTPMethods = retryHTTPMethods
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
            guard request.retryCount < retryLimit else {
                completion(.doNotRetry)
                return
            }
            let shouldRetry = await shouldRetry(request, dueTo: error)
            completion(shouldRetry)
        }
    }
}

extension MTInterceptor {
    // MARK: - Custom Methods
    func shouldRetry(_ request: Request, dueTo error: Error) async -> RetryResult {
        let statusCode = request.response?.statusCode
        
        if let statusCode {
            if delegate.tokenRefreshHttpsCodes.contains(statusCode) {
                return await handleTokenFailure()
            } else if retryHTTPStatusCodes.contains(statusCode) {
                return .retry
            } else {
                return .doNotRetry
            }
        } else {
            guard let httpMethod = request.request?.method, retryHTTPMethods.contains(httpMethod)
            else { return .doNotRetry }
            
            return shouldRetry(for: error)
        }
    }
    
    func shouldRetry(for error: Error) -> RetryResult {
        let errorCode = (error as? URLError)?.code
        let afErrorCode = (error.asAFError?.underlyingError as? URLError)?.code
        
        guard let code = errorCode ?? afErrorCode else { return .doNotRetry }
        
        return retryURLErrorCodes.contains(code) ? .retry : .doNotRetry
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
