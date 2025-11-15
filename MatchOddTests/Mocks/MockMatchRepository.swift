//
//  MockMatchRepository.swift
//  MatchOddTests
//
//  Description: Mock implementation of MatchRepositoryProtocol for testing
//  
//
//  Created by Link on 2025/11/13.
//

import Foundation
@testable import MatchOdd

// MARK: - MockMatchRepository

/// Mock repository for testing ViewModel logic
/// Allows injection of predefined data and errors
final class MockMatchRepository: MatchRepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    /// Matches to return from fetchMatches
    var matchesToReturn: [Match] = []

    /// Odds to return from fetchOdds
    var oddsToReturn: [Odds] = []

    /// Error to throw from fetchMatches
    var fetchMatchesError: Error?

    /// Error to throw from fetchOdds
    var fetchOddsError: Error?

    /// Delay for simulating network latency (in seconds)
    var delay: TimeInterval = 0

    /// Counter for tracking how many times fetchMatches was called
    private(set) var fetchMatchesCallCount = 0

    /// Counter for tracking how many times fetchOdds was called
    private(set) var fetchOddsCallCount = 0

    // MARK: - MatchRepositoryProtocol

    func fetchMatches() async throws -> [Match] {
        fetchMatchesCallCount += 1

        // Simulate network delay if configured
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        // Throw error if configured
        if let error = fetchMatchesError {
            throw error
        }

        return matchesToReturn
    }

    func fetchOdds() async throws -> [Odds] {
        fetchOddsCallCount += 1

        // Simulate network delay if configured
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        // Throw error if configured
        if let error = fetchOddsError {
            throw error
        }

        return oddsToReturn
    }

    // MARK: - Helper Methods

    /// Resets all counters and configured data
    func reset() {
        matchesToReturn = []
        oddsToReturn = []
        fetchMatchesError = nil
        fetchOddsError = nil
        delay = 0
        fetchMatchesCallCount = 0
        fetchOddsCallCount = 0
    }
}

// MARK: - Test Data Factory

extension MockMatchRepository {

    /// Creates sample match data for testing
    static func createSampleMatches() -> [Match] {
        return [
            Match(
                matchID: 1,
                teamA: "Team A",
                teamB: "Team B",
                startTime: Date(),
                isLive: false,
                currentMinute: nil,
                scoreA: nil,
                scoreB: nil
            ),
            Match(
                matchID: 2,
                teamA: "Team C",
                teamB: "Team D",
                startTime: Date().addingTimeInterval(3600),
                isLive: true,
                currentMinute: 45,
                scoreA: 1,
                scoreB: 2
            )
        ]
    }

    /// Creates sample odds data for testing
    static func createSampleOdds() -> [Odds] {
        return [
            Odds(matchID: 1, teamAOdds: 1.5, teamBOdds: 2.5, drawOdds: 3.0),
            Odds(matchID: 2, teamAOdds: 1.8, teamBOdds: 2.2, drawOdds: 2.8)
        ]
    }
}
