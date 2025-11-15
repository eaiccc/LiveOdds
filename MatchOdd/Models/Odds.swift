//
//  Odds.swift
//  MatchOdd
//
//  Description: Data model representing betting odds for a match with optional draw odds
//
//  Created by Link on 2025/11/13.
//

import Foundation

// MARK: - Odds Model

struct Odds: Codable, Hashable, Sendable {
    // MARK: - Properties
    
    let matchID: Int
    let teamAOdds: Double  // 主勝
    let teamBOdds: Double  // 客勝
    let drawOdds: Double?  // 和局（可選，某些運動無和局）
}
