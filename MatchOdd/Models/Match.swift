//
//  Match.swift
//  MatchOdd
//
//  Description: Data model representing a sports match with live status and scores
//
//  Created by Link on 2025/11/13.
//

import Foundation

// MARK: - Match Model

struct Match: Codable, Identifiable, Hashable, Sendable {
    // MARK: - Properties

    let matchID: Int
    let teamA: String
    let teamB: String
    let startTime: Date
    let isLive: Bool
    let currentMinute: Int?
    let scoreA: Int?
    let scoreB: Int?

    // MARK: - Computed Properties

    var id: Int { matchID }
}
