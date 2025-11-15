//
//  OddsStore.swift
//  MatchOdd
//
//  Description: Thread-safe actor for storing and managing real-time odds updates from WebSocket
//
//  Created by Link on 2025/11/13.
//

import Foundation

// MARK: - OddsStore Actor

/// Thread-safe actor for storing and managing real-time odds updates from WebSocket connections
/// Provides concurrent access to odds data with actor isolation guarantees
actor OddsStore {
    // MARK: - Properties
    
    /// Internal storage mapping match IDs to their corresponding odds
    private var oddsMap: [Int: Odds] = [:]
    
    // MARK: - Public Methods
    
    /// Updates or inserts odds for a specific match
    /// - Parameter odds: The odds object to store or update
    func update(_ odds: Odds) {
        oddsMap[odds.matchID] = odds
    }
    
    /// Retrieves odds for a specific match ID
    /// - Parameter matchID: The unique identifier for the match
    /// - Returns: The odds object if found, nil otherwise
    func get(_ matchID: Int) -> Odds? {
        return oddsMap[matchID]
    }
    
    /// Retrieves all stored odds
    /// - Returns: An array containing all stored odds objects
    func getAll() -> [Odds] {
        return Array(oddsMap.values)
    }
}
