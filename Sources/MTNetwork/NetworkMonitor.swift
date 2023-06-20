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

extension NWInterface.InterfaceType: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
            case .other:
                return "other"
            case .wifi:
                return "wifi"
            case .cellular:
                return "cellular"
            case .wiredEthernet:
                return "wiredEthernet"
            case .loopback:
                return "loopback"
            @unknown default:
                return "unknown"
        }
    }
}

extension Optional where Wrapped == NWInterface.InterfaceType {
    public var debugDescription: String {
        switch self {
            case .none:
                return "not found"
            case .some(let wrapped):
                return wrapped.debugDescription
        }
    }
}

// MARK: - Network Actor

@globalActor
/// Custom Global Actor to avoid Data Race, use this to execute a code in global actor rather than MainActor(i.e MainThread)
struct NetworkActor {
    actor ActorType { }
    
    static let shared: ActorType = ActorType()
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
            guard CommandLine.arguments.contains(Constant.monitorNetworkArgument) else { return }
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
        Task { @NetworkActor in
            monitor.pathUpdateHandler = { [weak self] path in
                self?.isConnected = (path.status != .unsatisfied)
                self?.isExpensive = path.isExpensive
                self?.currentConnectionType = NWInterface.InterfaceType.allCases.filter { path.usesInterfaceType($0) }.first
                
                NotificationCenter.default.post(name: .connectivityStatus, object: nil)
            }
            monitor.start(queue: queue)
        }
    }
    
    public func stopMonitoring() {
        monitor.cancel()
    }
}
