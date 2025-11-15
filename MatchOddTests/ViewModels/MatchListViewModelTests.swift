//
//  MatchListViewModelTests.swift
//  MatchOddTests
//
//  Description: Unit tests for MatchListViewModel
//  
//
//  Created by Link on 2025/11/13.
//

import Testing
import Combine
import Foundation
@testable import MatchOdd

// MARK: - MatchListViewModelTests

@MainActor
struct MatchListViewModelTests {

    // MARK: - Properties

    var sut: MatchListViewModel!
    var mockRepository: MockMatchRepository!
    var mockStreamManager: MockOddsStreamManager!

    // MARK: - Setup

    init() {
        mockRepository = MockMatchRepository()
        mockStreamManager = MockOddsStreamManager()
        sut = MatchListViewModel(
            repository: mockRepository,
            oddsStreamManager: mockStreamManager
        )
    }

    // MARK: - Initial Data Loading Tests

    @Test("Load initial data successfully")
    func testLoadInitialDataSuccess() async throws {
        // Given
        mockRepository.matchesToReturn = MockMatchRepository.createSampleMatches()
        mockRepository.oddsToReturn = MockMatchRepository.createSampleOdds()

        // When
        await sut.loadInitialData()

        // Then
        #expect(sut.matches.count == 2, "Should load 2 matches")
        #expect(sut.isLoading == false, "Loading should be false after completion")
        #expect(sut.error == nil, "Error should be nil on success")
        #expect(mockRepository.fetchMatchesCallCount == 1, "Should call fetchMatches once")
        #expect(mockRepository.fetchOddsCallCount == 1, "Should call fetchOdds once")
    }

    @Test("Load initial data with fetch matches error")
    func testLoadInitialDataFetchMatchesError() async throws {
        // Given
        enum TestError: Error {
            case matchesFailed
        }
        mockRepository.fetchMatchesError = TestError.matchesFailed
        mockRepository.oddsToReturn = MockMatchRepository.createSampleOdds()

        // When
        await sut.loadInitialData()

        // Then
        #expect(sut.matches.isEmpty, "Matches should be empty on error")
        #expect(sut.isLoading == false, "Loading should be false after error")
        #expect(sut.error != nil, "Error should be set")
    }

    @Test("Load initial data with fetch odds error")
    func testLoadInitialDataFetchOddsError() async throws {
        // Given
        enum TestError: Error {
            case oddsFailed
        }
        mockRepository.matchesToReturn = MockMatchRepository.createSampleMatches()
        mockRepository.fetchOddsError = TestError.oddsFailed

        // When
        await sut.loadInitialData()

        // Then
        #expect(sut.matches.isEmpty, "Matches should be empty on error")
        #expect(sut.isLoading == false, "Loading should be false after error")
        #expect(sut.error != nil, "Error should be set")
    }

    @Test("Loading state changes during data fetch")
    func testLoadingStateChanges() async throws {
        // Given
        mockRepository.matchesToReturn = MockMatchRepository.createSampleMatches()
        mockRepository.oddsToReturn = MockMatchRepository.createSampleOdds()
        mockRepository.delay = 0.1  // Add small delay to capture loading state

        var loadingStates: [Bool] = []

        // Create task to capture loading states
        let monitorTask = Task { @MainActor in
            for _ in 0..<10 {
                loadingStates.append(sut.isLoading)
                try? await Task.sleep(nanoseconds: 20_000_000)  // 20ms
            }
        }

        // When
        await sut.loadInitialData()
        await monitorTask.value

        // Then
        #expect(loadingStates.contains(true), "Should have loading state as true during fetch")
        #expect(sut.isLoading == false, "Loading should be false after completion")
    }

    // MARK: - Odds Update Tests

    @Test("Handle real-time odds update")
    func testHandleOddsUpdate() async throws {
        // Given - Load initial data first
        mockRepository.matchesToReturn = MockMatchRepository.createSampleMatches()
        mockRepository.oddsToReturn = MockMatchRepository.createSampleOdds()
        await sut.loadInitialData()

        // Find match with ID 1 specifically
        let match1 = sut.matches.first { $0.matchID == 1 }
        let initialOdds = match1?.teamAOdds
        #expect(initialOdds == 1.5, "Initial odds for match 1 should be 1.5")

        // When - Emit odds update
        let update = MockOddsStreamManager.createSampleUpdate(
            matchID: 1,
            teamAOdds: 1.8,
            teamBOdds: 2.3,
            drawOdds: 3.2
        )
        mockStreamManager.emitUpdate(update)

        // Wait for update to propagate
        try await Task.sleep(nanoseconds: 100_000_000)  // 100ms

        // Then
        let updatedMatch = sut.matches.first { $0.matchID == 1 }
        #expect(updatedMatch?.teamAOdds == 1.8, "TeamA odds should be updated to 1.8")
        #expect(updatedMatch?.teamBOdds == 2.3, "TeamB odds should be updated to 2.3")
        #expect(updatedMatch?.drawOdds == 3.2, "Draw odds should be updated to 3.2")
    }

    @Test("Odds change flags are set correctly")
    func testOddsChangeFlags() async throws {
        // Given - Load initial data
        mockRepository.matchesToReturn = MockMatchRepository.createSampleMatches()
        mockRepository.oddsToReturn = MockMatchRepository.createSampleOdds()
        await sut.loadInitialData()

        // When - Emit odds update with changed values
        let update = MockOddsStreamManager.createSampleUpdate(
            matchID: 1,
            teamAOdds: 1.9,  // Changed
            teamBOdds: 2.5,  // Same
            drawOdds: 3.5    // Changed
        )
        mockStreamManager.emitUpdate(update)

        // Wait for update
        try await Task.sleep(nanoseconds: 50_000_000)  // 50ms

        // Then
        let updatedMatch = sut.matches.first { $0.matchID == 1 }
        #expect(updatedMatch?.teamAOddsDidChange == true, "TeamA odds change flag should be true")
        #expect(updatedMatch?.teamBOddsDidChange == false, "TeamB odds change flag should be false (no change)")
        #expect(updatedMatch?.drawOddsDidChange == true, "Draw odds change flag should be true")
    }

    @Test("Odds change flags reset after delay")
    func testOddsChangeFlagsReset() async throws {
        // Given - Load initial data
        mockRepository.matchesToReturn = MockMatchRepository.createSampleMatches()
        mockRepository.oddsToReturn = MockMatchRepository.createSampleOdds()
        await sut.loadInitialData()

        // When - Emit odds update
        let update = MockOddsStreamManager.createSampleUpdate(
            matchID: 1,
            teamAOdds: 2.0,
            teamBOdds: 2.5,
            drawOdds: 3.0
        )
        mockStreamManager.emitUpdate(update)

        // Wait for initial update
        try await Task.sleep(nanoseconds: 50_000_000)  // 50ms

        // Verify flags are set
        var updatedMatch = sut.matches.first { $0.matchID == 1 }
        #expect(updatedMatch?.teamAOddsDidChange == true, "Flag should be true initially")

        // Wait for flags to reset (300ms as per ViewModel implementation)
        try await Task.sleep(nanoseconds: 400_000_000)  // 400ms

        // Then - Flags should be reset
        updatedMatch = sut.matches.first { $0.matchID == 1 }
        #expect(updatedMatch?.teamAOddsDidChange == false, "Flag should be reset to false")
    }

    // MARK: - Match Sorting Tests

    @Test("Live matches appear first in sorted list")
    func testLiveMatchesSortedFirst() async throws {
        // Given - Create matches with different live states
        let futureDate = Date().addingTimeInterval(3600)
        let pastDate = Date().addingTimeInterval(-3600)

        mockRepository.matchesToReturn = [
            Match(matchID: 1, teamA: "A", teamB: "B", startTime: futureDate, isLive: false, currentMinute: nil, scoreA: nil, scoreB: nil),
            Match(matchID: 2, teamA: "C", teamB: "D", startTime: pastDate, isLive: true, currentMinute: 45, scoreA: 1, scoreB: 0),
            Match(matchID: 3, teamA: "E", teamB: "F", startTime: Date(), isLive: false, currentMinute: nil, scoreA: nil, scoreB: nil)
        ]
        mockRepository.oddsToReturn = [
            Odds(matchID: 1, teamAOdds: 1.5, teamBOdds: 2.5, drawOdds: 3.0),
            Odds(matchID: 2, teamAOdds: 1.8, teamBOdds: 2.2, drawOdds: 2.8),
            Odds(matchID: 3, teamAOdds: 2.0, teamBOdds: 2.0, drawOdds: 2.5)
        ]

        // When
        await sut.loadInitialData()

        // Then
        #expect(sut.matches.first?.isLive == true, "First match should be live")
        #expect(sut.matches.first?.matchID == 2, "Match ID 2 should be first (it's live)")
    }

    // MARK: - Error Handling Tests

    @Test("Error is cleared when loading succeeds after failure")
    func testErrorClearedOnSuccess() async throws {
        // Given - First load fails
        enum TestError: Error {
            case failed
        }
        mockRepository.fetchMatchesError = TestError.failed
        await sut.loadInitialData()
        #expect(sut.error != nil, "Error should be set after failure")

        // When - Second load succeeds
        mockRepository.fetchMatchesError = nil
        mockRepository.matchesToReturn = MockMatchRepository.createSampleMatches()
        mockRepository.oddsToReturn = MockMatchRepository.createSampleOdds()
        await sut.loadInitialData()

        // Then
        #expect(sut.error == nil, "Error should be cleared on success")
        #expect(sut.matches.count == 2, "Should have loaded matches")
    }

    // MARK: - Integration Tests

    @Test("Multiple odds updates are handled correctly")
    func testMultipleOddsUpdates() async throws {
        // Given
        mockRepository.matchesToReturn = MockMatchRepository.createSampleMatches()
        mockRepository.oddsToReturn = MockMatchRepository.createSampleOdds()
        await sut.loadInitialData()

        // When - Emit multiple updates
        let updates = [
            MockOddsStreamManager.createSampleUpdate(matchID: 1, teamAOdds: 1.6, teamBOdds: 2.4, drawOdds: 3.1),
            MockOddsStreamManager.createSampleUpdate(matchID: 2, teamAOdds: 1.9, teamBOdds: 2.1, drawOdds: 2.9),
            MockOddsStreamManager.createSampleUpdate(matchID: 1, teamAOdds: 1.7, teamBOdds: 2.3, drawOdds: 3.2)
        ]
        mockStreamManager.emitUpdates(updates)

        // Wait for all updates
        try await Task.sleep(nanoseconds: 150_000_000)  // 150ms

        // Then - Last update for match 1 should be reflected
        let match1 = sut.matches.first { $0.matchID == 1 }
        #expect(match1?.teamAOdds == 1.7, "Should have latest odds for match 1")

        let match2 = sut.matches.first { $0.matchID == 2 }
        #expect(match2?.teamAOdds == 1.9, "Should have updated odds for match 2")
    }

    @Test("Empty data is handled gracefully")
    func testEmptyDataHandling() async throws {
        // Given - No matches or odds
        mockRepository.matchesToReturn = []
        mockRepository.oddsToReturn = []

        // When
        await sut.loadInitialData()

        // Then
        #expect(sut.matches.isEmpty, "Matches should be empty")
        #expect(sut.isLoading == false, "Loading should be false")
        #expect(sut.error == nil, "No error for empty data")
    }
}
