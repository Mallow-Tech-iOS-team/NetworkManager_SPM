//
//  EventMonitor.swift
//  
//
//  Created by Dhanushkumar Kanagaraj on 15/09/22.
//

import Alamofire
import Foundation

// MARK: - Request Event Monitor

/// Use this event monitor to listen to the requests data, response, metrics, etc
public class RequestEventMonitor: EventMonitor {
    public let queue = DispatchQueue(label: "com.mallow-tech.debug-event-monitor")
    
    // MARK: - Initialisers
    
    public init() { }
    
    // MARK: - Inherited Methods
    
    /// Listens to the request's starts or resumes event
    public func requestDidResume(_ request: Request) {
        print("⚡️ URL: \(request.description)")
        print("⚡️ Request Headers: \(request.request?.allHTTPHeaderFields?.debugDescription ?? "")")
        if let data = request.request?.httpBody {
            let body = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            print("⚡️ Request Body: \(String(describing: body))")
        } else {
            print("⚡️ Request Body: NIL")
        }
    }
    
    /// Listens to the request's Data Metrics
    public func request(_ request: Request,
                 didGatherMetrics metrics: URLSessionTaskMetrics) {
        print("⏱ Request Duration: ", metrics.taskInterval)
    }
    
    /// Starts off when the request is completed
    public func request<Value>(_ request: DataRequest,
                        didParseResponse response: DataResponse<Value, AFError>) {
        if let data = response.data {
            print("✅ Response Headers: \(request.response?.allHeaderFields.debugDescription ?? "")")
            if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) {
                print("✅ Success Response: \(json)")
            } else {
                print("✅❌ Success Response: Json Parsing failed")
            }
        }
        
        if let error = response.error {
            print("❌ Response Headers: \(request.response?.allHeaderFields.debugDescription ?? "")")
            print("❌ Status Code: \(String(describing: error.responseCode))")
            print("❌ Error: \(String(describing: error.errorDescription))")
        }
    }
}
