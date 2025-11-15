//
//  MatchListViewModel.swift
//  MatchOdd
//
//  Description: Main actor view model for managing match list state with real-time odds updates
//  @MainActor for UI thread safety
//
//  Created by Link on 2025/11/13.
//

import Foundation
import Combine

// MARK: - MatchListViewModel

/// Main actor view model for managing match list display and real-time updates
/// Coordinates data fetching, odds streaming, and UI state management
/// Swift 6 @MainActor ensures all UI updates happen on the main thread
@MainActor
final class MatchListViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Array of match view data for display in the UI
    /// Published for SwiftUI/Combine observation
    @Published var matches: [MatchViewData] = []
    
    /// Loading state indicator for UI feedback
    /// True when fetching data or processing updates
    @Published var isLoading: Bool = false
    
    /// Error state for displaying error messages to users
    /// Nil when no error, contains error details when present
    @Published var error: Error?

    /// Connection state for WebSocket stream
    /// Indicates current connection status for UI feedback
    @Published var connectionState: ConnectionState = .disconnected
    
    /// Animation settings for odds changes
    /// Controls whether odds change animations are displayed
    @Published var animationsEnabled: Bool = true

    // MARK: - Private Properties
    
    /// Repository for accessing match and odds data
    /// Handles network requests and data fetching operations
    private let repository: MatchRepositoryProtocol
    
    /// WebSocket manager for real-time odds updates
    /// Provides streaming updates for live odds changes
    private let oddsStreamManager: OddsStreamManagerProtocol
    
    /// Thread-safe store for managing odds data
    /// Centralized storage for real-time odds updates
    private let oddsStore: OddsStore
    
    /// Current matches data for merging with odds
    /// Cached matches array for efficient odds updates
    private var currentMatches: [Match] = []
    
    /// Set of Combine cancellables for memory management
    /// Stores active subscriptions to prevent memory leaks
    private var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the view model with required dependencies
    /// - Parameters:
    ///   - repository: Repository implementing MatchRepositoryProtocol
    ///   - oddsStreamManager: Stream manager implementing OddsStreamManagerProtocol
    init(
        repository: MatchRepositoryProtocol,
        oddsStreamManager: OddsStreamManagerProtocol
    ) {
        self.repository = repository
        self.oddsStreamManager = oddsStreamManager
        self.oddsStore = OddsStore()
        
        setupOddsStreaming()
    }
    
    // MARK: - Public Methods
    
    /// Loads initial match and odds data from repository
    /// Sets loading state, fetches data concurrently, and handles errors
    func loadInitialData() async {
        isLoading = true
        error = nil
        
        do {
            // Fetch matches and odds concurrently for better performance
            async let matchesResult = repository.fetchMatches()
            async let oddsResult = repository.fetchOdds()
            
            let (fetchedMatches, fetchedOdds) = try await (matchesResult, oddsResult)
            
            // Store matches for future merging operations
            currentMatches = fetchedMatches
            
            // Store odds data in the odds store for real-time updates
            for odds in fetchedOdds {
                await oddsStore.update(odds)
            }
            
            // Merge matches with odds and update UI
            matches = await mergeMatchesWithOdds()
            
        } catch {
            // Update error state for UI display
            self.error = error
        }
        
        isLoading = false
    }

    /// Simulates a connection failure for testing reconnection logic
    /// Triggers automatic reconnection mechanism
    func simulateDisconnection() {
        oddsStreamManager.simulateDisconnection()
    }
    
    /// Toggles animation settings for odds changes
    func toggleAnimations() {
        animationsEnabled.toggle()
        print("Animations \(animationsEnabled ? "enabled" : "disabled")")
    }

    // MARK: - Private Methods
    
    /// Sets up real-time odds streaming subscription
    /// Subscribes to odds updates from the stream manager and updates the odds store
    private func setupOddsStreaming() {
        // Subscribe to odds updates
        oddsStreamManager.oddsUpdatePublisher
            .sink { [weak self] oddsUpdate in
                Task { @MainActor in
                    await self?.handleOddsUpdate(oddsUpdate)
                }
            }
            .store(in: &cancellables)

        // Subscribe to connection state changes
        oddsStreamManager.connectionStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.connectionState = state
                print("Connection state: \(state)")
            }
            .store(in: &cancellables)
    }
    
    /// Handles incoming odds updates from the stream
    /// - Parameter oddsUpdate: The odds update received from the stream
    private func handleOddsUpdate(_ oddsUpdate: OddsUpdate) async {
        // Convert OddsUpdate to Odds for storage
        let odds = Odds(
            matchID: oddsUpdate.matchID,
            teamAOdds: oddsUpdate.teamAOdds,
            teamBOdds: oddsUpdate.teamBOdds,
            drawOdds: oddsUpdate.drawOdds
        )
        print("Received odds update: \(oddsUpdate)")
        await oddsStore.update(odds)
        // Update matches array with new odds data and animation flags
        await updateMatchesWithOddsAnimation(oddsUpdate)
    }
    
    /// Merges matches with odds data and applies sorting logic
    /// - Returns: Array of MatchViewData sorted by live status and start time
    private func mergeMatchesWithOdds() async -> [MatchViewData] {
        // Get current odds from the store
        let allOdds = await oddsStore.getAll()
        
        // Use compactMap to filter unmatched entries and create MatchViewData
        let matchViewDataList = currentMatches.compactMap { match -> MatchViewData? in
            // Find corresponding odds for this match
            guard let matchOdds = allOdds.first(where: { $0.matchID == match.matchID }) else {
                return nil // Filter out matches without corresponding odds
            }
            
            // Find previous odds for change detection
            let previousOdds = matches.first { $0.matchID == match.matchID }
            let previousOddsModel = previousOdds.map { viewData in
                Odds(
                    matchID: viewData.matchID,
                    teamAOdds: viewData.teamAOdds,
                    teamBOdds: viewData.teamBOdds,
                    drawOdds: viewData.drawOdds
                )
            }
            
            return MatchViewData.create(from: match, odds: matchOdds, previousOdds: previousOddsModel)
        }
        
        // Sort: LIVE matches first, then by startTime ascending
        return matchViewDataList.sorted { lhs, rhs in
            // LIVE matches come first
            if lhs.isLive != rhs.isLive {
                return lhs.isLive && !rhs.isLive
            }
            // Then sort by start time ascending
            return lhs.startTime < rhs.startTime
        }
    }
    
    /// Updates the matches array with the latest odds from the store
    /// Refreshes the UI with current odds information
    private func updateMatchesWithNewOdds() async {
        // Merge current matches with updated odds and refresh UI
        matches = await mergeMatchesWithOdds()
    }
    
    /// Updates matches with animation flags for odds changes
    /// - Parameter oddsUpdate: The odds update containing changed values
    private func updateMatchesWithOddsAnimation(_ oddsUpdate: OddsUpdate) async {
        // Find the match index to update
        guard let matchIndex = matches.firstIndex(where: { $0.matchID == oddsUpdate.matchID }) else {
            // If match not found, perform regular update
            await updateMatchesWithNewOdds()
            return
        }
        
        let currentMatch = matches[matchIndex]
        
        // Determine which odds changed for animation flags
        let teamAChanged = currentMatch.teamAOdds != oddsUpdate.teamAOdds
        let teamBChanged = currentMatch.teamBOdds != oddsUpdate.teamBOdds
        let drawChanged = currentMatch.drawOdds != oddsUpdate.drawOdds
        
        // Create updated match data with animation flags
        var updatedMatch = currentMatch
        updatedMatch.teamAOdds = oddsUpdate.teamAOdds
        updatedMatch.teamBOdds = oddsUpdate.teamBOdds
        updatedMatch.drawOdds = oddsUpdate.drawOdds
        updatedMatch.teamAOddsDidChange = teamAChanged
        updatedMatch.teamBOddsDidChange = teamBChanged
        updatedMatch.drawOddsDidChange = drawChanged
        
        // Update the matches array
        matches[matchIndex] = updatedMatch
        
        // Reset animation flags after 0.3 seconds
        if teamAChanged || teamBChanged || drawChanged {
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                
                // Reset animation flags
                if matchIndex < matches.count && matches[matchIndex].matchID == oddsUpdate.matchID {
                    matches[matchIndex].teamAOddsDidChange = false
                    matches[matchIndex].teamBOddsDidChange = false
                    matches[matchIndex].drawOddsDidChange = false
                }
            }
        }
    }
}
