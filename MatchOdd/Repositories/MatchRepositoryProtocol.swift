//
//  MatchRepositoryProtocol.swift
//  MatchOdd
//
//  Description: Protocol defining repository contract for data access layer with async/await support
//
//  Created by Link on 2025/11/13.
//

import Foundation

// MARK: - Match Repository Protocol

/// Repository protocol defining the contract for data access layer operations
/// Provides async methods for fetching matches and odds data
protocol MatchRepositoryProtocol: Sendable {
    /// Fetches all available matches from the data source
    /// - Returns: An array of Match objects
    /// - Throws: Error if the fetch operation fails
    func fetchMatches() async throws -> [Match]
    
    /// Fetches all available odds from the data source
    /// - Returns: An array of Odds objects
    /// - Throws: Error if the fetch operation fails
    func fetchOdds() async throws -> [Odds]
}
