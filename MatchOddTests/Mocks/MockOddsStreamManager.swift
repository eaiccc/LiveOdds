//
//  MockOddsStreamManager.swift
//  MatchOddTests
//
//  Description: Mock implementation of OddsStreamManagerProtocol for testing
//  
//
//  Created by Link on 2025/11/13.
//

import Foundation
import Combine
@testable import MatchOdd

// MARK: - MockOddsStreamManager

/// Mock odds stream manager for testing real-time updates
/// Provides manual control over odds updates for deterministic testing
final class MockOddsStreamManager: OddsStreamManagerProtocol, @unchecked Sendable {

    // MARK: - Properties

    /// Publisher for odds updates
    private let oddsUpdateSubject = PassthroughSubject<OddsUpdate, Never>()

    var oddsUpdatePublisher: AnyPublisher<OddsUpdate, Never> {
        oddsUpdateSubject.eraseToAnyPublisher()
    }

    /// Publisher for connection state changes
    private let connectionStateSubject = CurrentValueSubject<ConnectionState, Never>(.connected)

    var connectionStatePublisher: AnyPublisher<ConnectionState, Never> {
        connectionStateSubject.eraseToAnyPublisher()
    }

    /// Flag indicating whether streaming is active
    private(set) var isStreaming = false

    /// Counter for tracking start calls
    private(set) var startStreamingCallCount = 0

    /// Counter for tracking stop calls
    private(set) var stopStreamingCallCount = 0

    /// Counter for tracking disconnection simulation calls
    private(set) var simulateDisconnectionCallCount = 0

    // MARK: - OddsStreamManagerProtocol

    func startStreaming() {
        isStreaming = true
        startStreamingCallCount += 1
    }

    func stopStreaming() {
        isStreaming = false
        stopStreamingCallCount += 1
    }

    func simulateDisconnection() {
        simulateDisconnectionCallCount += 1
        connectionStateSubject.send(.disconnected)
    }

    // MARK: - Test Helper Methods

    /// Manually emit an odds update for testing
    /// - Parameter update: The odds update to emit
    func emitUpdate(_ update: OddsUpdate) {
        oddsUpdateSubject.send(update)
    }

    /// Emit multiple odds updates
    /// - Parameter updates: Array of odds updates to emit
    func emitUpdates(_ updates: [OddsUpdate]) {
        updates.forEach { oddsUpdateSubject.send($0) }
    }

    /// Resets all counters and state
    func reset() {
        isStreaming = false
        startStreamingCallCount = 0
        stopStreamingCallCount = 0
    }
}

// MARK: - Test Data Factory

extension MockOddsStreamManager {

    /// Creates a sample odds update for testing
    static func createSampleUpdate(
        matchID: Int = 1,
        teamAOdds: Double = 1.5,
        teamBOdds: Double = 2.5,
        drawOdds: Double? = 3.0
    ) -> OddsUpdate {
        return OddsUpdate(
            matchID: matchID,
            teamAOdds: teamAOdds,
            teamBOdds: teamBOdds,
            drawOdds: drawOdds,
            timestamp: Date()
        )
    }
}
