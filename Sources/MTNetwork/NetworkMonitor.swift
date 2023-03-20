//
//  NetworkMonitor.swift
//  
//
//  Created by Dhanushkumar Kanagaraj on 06/11/22.
//

import Foundation
import Network

// MARK: - Extension
extension Notification.Name {
    public static let connectivityStatus = Notification.Name(rawValue: "connectivityStatusChanged")
}

extension NWInterface.InterfaceType: CaseIterable {
    public static var allCases: [NWInterface.InterfaceType] = [
        .other,
        .wifi,
        .cellular,
        .loopback,
        .wiredEthernet
    ]
}

// MARK: - Protocol
public protocol NetworkMonitorProtocol {
    var isConnected: Bool { get }
    var isExpensive: Bool { get }
    var currentConnectionType: NWInterface.InterfaceType? { get }
    
    func startMonitoring()
    func stopMonitoring()
}

// MARK: - Network Monitor
public final class NetworkMonitor: ObservableObject, NetworkMonitorProtocol {
    public static let shared = NetworkMonitor()
    
    private let queue = DispatchQueue(label: "NetworkConnectivityMonitor")
    private let monitor: NWPathMonitor
    
    public private(set) var isConnected = false {
        didSet {
            print("🗼 Network Connected -- ", isConnected)
        }
    }
    public private(set) var isExpensive = false
    public private(set) var currentConnectionType: NWInterface.InterfaceType?
    
    // MARK: - Initialisers
    private init() {
        monitor = NWPathMonitor()
    }
    
    // MARK: - Custom Methods
    public func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = (path.status != .unsatisfied)
            self?.isExpensive = path.isExpensive
            self?.currentConnectionType = NWInterface.InterfaceType.allCases.filter { path.usesInterfaceType($0) }.first
            
            NotificationCenter.default.post(name: .connectivityStatus, object: nil)
        }
        monitor.start(queue: queue)
    }
    
    public func stopMonitoring() {
        monitor.cancel()
    }
}
