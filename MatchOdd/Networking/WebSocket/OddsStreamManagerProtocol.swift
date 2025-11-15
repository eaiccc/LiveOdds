//
//  OddsStreamManagerProtocol.swift
//  MatchOdd
//
//  Description: Protocol defining WebSocket streaming contract for real-time odds updates
//  Sendable conformance for cross-actor safety
//
//  Created by Link on 2025/11/13.
//

import Foundation
import Combine

// MARK: - ConnectionState

/// Enumeration representing the connection state of the stream manager
enum ConnectionState: Sendable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int)
}

// MARK: - OddsStreamManagerProtocol

/// Protocol defining the contract for WebSocket streaming managers
/// Provides real-time odds updates through Combine publisher pattern
/// Swift 6 Sendable conformance ensures thread-safe usage across actors
protocol OddsStreamManagerProtocol: Sendable {
    // MARK: - Properties

    /// Publisher for real-time odds updates
    /// Emits OddsUpdate objects when new odds data is received
    /// Never fails, ensuring continuous streaming
    var oddsUpdatePublisher: AnyPublisher<OddsUpdate, Never> { get }

    /// Publisher for connection state changes
    /// Emits current connection state for UI feedback
    var connectionStatePublisher: AnyPublisher<ConnectionState, Never> { get }

    // MARK: - Methods

    /// Starts the WebSocket streaming connection
    /// Begins listening for odds updates and publishing them to oddsUpdatePublisher
    func startStreaming()

    /// Stops the WebSocket streaming connection
    /// Cleans up resources and stops publishing updates
    func stopStreaming()

    /// Simulates a connection failure (for testing/development)
    /// Triggers automatic reconnection mechanism
    func simulateDisconnection()
}
