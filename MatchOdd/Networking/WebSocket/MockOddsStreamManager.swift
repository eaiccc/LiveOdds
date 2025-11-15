//
//  MockOddsStreamManager.swift
//  MatchOdd
//
//  Description: Mock implementation of OddsStreamManager with auto-reconnect capability
//  Generates 0-10 random odds updates per second with ±5% odds variation for development testing
//
//  Created by Link on 2025/11/13.
//

import Foundation
import Combine

// MARK: - MockOddsStreamManager

/// Mock implementation of OddsStreamManagerProtocol for development testing
/// Simulates WebSocket push notifications with automatic reconnection on failure
/// Generates realistic odds variations with ±5% fluctuation from base values
final class MockOddsStreamManager: @unchecked Sendable, OddsStreamManagerProtocol {

    // MARK: - Properties

    /// Timer subscription for periodic updates
    private var timer: AnyCancellable?

    /// Timer for reconnection delays
    private var reconnectionTimer: AnyCancellable?

    /// Subject for broadcasting odds updates
    private let updateSubject = PassthroughSubject<OddsUpdate, Never>()

    /// Subject for broadcasting connection state
    private let connectionStateSubject = CurrentValueSubject<ConnectionState, Never>(.disconnected)

    /// Match IDs to generate updates for (1-30 as per MockDataProvider)
    private let matchIDs: [Int] = Array(1...100)

    /// Base odds values for consistent variation calculation
    private var baseOdds: [Int: (teamA: Double, teamB: Double, draw: Double?)] = [:]

    /// Current reconnection attempt count
    private var reconnectionAttempt: Int = 0

    /// Maximum reconnection attempts before giving up
    private let maxReconnectionAttempts = 5

    /// Flag indicating if auto-reconnect is enabled
    private var shouldAutoReconnect = true

    // MARK: - OddsStreamManagerProtocol Conformance

    /// Publisher for real-time odds updates
    var oddsUpdatePublisher: AnyPublisher<OddsUpdate, Never> {
        updateSubject.eraseToAnyPublisher()
    }

    /// Publisher for connection state changes
    var connectionStatePublisher: AnyPublisher<ConnectionState, Never> {
        connectionStateSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    init() {
        initializeBaseOdds()
    }

    // MARK: - Public Methods

    /// Starts the timer-based streaming simulation
    /// Emits 0-10 random odds updates per second with realistic variations
    func startStreaming() {
        print("Starting stream connection...")
        connectionStateSubject.send(.connecting)

        // Simulate connection delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.connect()
        }
    }

    /// Stops the streaming simulation and cleans up resources
    func stopStreaming() {
        print("Stopping stream connection...")
        shouldAutoReconnect = false
        disconnect()
        connectionStateSubject.send(.disconnected)
    }

    /// Simulates a connection failure for testing reconnection logic
    func simulateDisconnection() {
        print("Simulating disconnection...")
        disconnect()
        connectionStateSubject.send(.disconnected)

        if shouldAutoReconnect {
            scheduleReconnection()
        }
    }

    // MARK: - Private Methods

    /// Establishes the connection and starts streaming
    private func connect() {
        reconnectionAttempt = 0
        connectionStateSubject.send(.connected)
        print("Stream connected")

        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.generateRandomUpdates()
            }
    }

    /// Disconnects and cleans up resources
    private func disconnect() {
        timer?.cancel()
        timer = nil
        reconnectionTimer?.cancel()
        reconnectionTimer = nil
    }

    /// Schedules a reconnection attempt with exponential backoff
    private func scheduleReconnection() {
        reconnectionAttempt += 1

        guard reconnectionAttempt <= maxReconnectionAttempts else {
            print("Max reconnection attempts reached. Giving up.")
            connectionStateSubject.send(.disconnected)
            return
        }

        // Exponential backoff: 2^attempt seconds (2, 4, 8, 16, 32...)
        let delay = min(pow(2.0, Double(reconnectionAttempt)), 32.0)

        print("Reconnection attempt \(reconnectionAttempt)/\(maxReconnectionAttempts) in \(delay)s...")
        connectionStateSubject.send(.reconnecting(attempt: reconnectionAttempt))

        reconnectionTimer = Timer.publish(every: delay, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [weak self] _ in
                self?.attemptReconnection()
            }
    }

    /// Attempts to reconnect to the stream
    private func attemptReconnection() {
        print("Attempting to reconnect...")
        connectionStateSubject.send(.connecting)

        // Simulate connection attempt (70% success rate for testing)
        let shouldSucceed = Double.random(in: 0...1) < 0.7

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            if shouldSucceed {
                print("Reconnection successful!")
                self?.connect()
            } else {
                print("Reconnection failed")
                self?.scheduleReconnection()
            }
        }
    }

    /// Initializes base odds values for all matches
    /// Uses realistic odds ranges (1.20-5.00) similar to MockDataProvider
    private func initializeBaseOdds() {
        for matchID in matchIDs {
            let teamAOdds = Double.random(in: 1.20...5.00)
            let teamBOdds = Double.random(in: 1.20...5.00)

            // 70% chance of having draw odds (football matches)
            let hasDrawOdds = Double.random(in: 0...1) < 0.7
            let drawOdds = hasDrawOdds ? Double.random(in: 2.8...4.5) : nil

            baseOdds[matchID] = (
                teamA: (teamAOdds * 100).rounded() / 100,
                teamB: (teamBOdds * 100).rounded() / 100,
                draw: drawOdds != nil ? (drawOdds! * 100).rounded() / 100 : nil
            )
        }
    }

    /// Generates 0-10 random odds updates per timer tick
    /// Each update applies ±5% variation to base odds values
    private func generateRandomUpdates() {
        let updateCount = Int.random(in: 0...10)
        let selectedMatchIDs = matchIDs.shuffled().prefix(updateCount)

        for matchID in selectedMatchIDs {
            guard let baseOddsForMatch = baseOdds[matchID] else { continue }

            let update = OddsUpdate(
                matchID: matchID,
                teamAOdds: applyVariation(to: baseOddsForMatch.teamA),
                teamBOdds: applyVariation(to: baseOddsForMatch.teamB),
                drawOdds: baseOddsForMatch.draw != nil ? applyVariation(to: baseOddsForMatch.draw!) : nil,
                timestamp: Date()
            )

            updateSubject.send(update)
        }
    }

    /// Applies ±5% variation to odds value
    /// - Parameter baseOdds: Original odds value
    /// - Returns: Varied odds value rounded to 2 decimal places
    private func applyVariation(to baseOdds: Double) -> Double {
        // Generate variation between -5% and +5%
        let variationPercent = Double.random(in: -0.05...0.05)
        let newOdds = baseOdds * (1.0 + variationPercent)

        // Ensure odds stay within realistic bounds (1.01-10.00)
        let clampedOdds = max(1.01, min(10.00, newOdds))

        // Round to 2 decimal places
        return (clampedOdds * 100).rounded() / 100
    }
}
