//
//  OddsUpdate.swift
//  MatchOdd
//
//  Description: Data model for WebSocket odds updates with timestamp for real-time odds tracking
//
//  Created by Link on 2025/11/13.
//

import Foundation

// MARK: - OddsUpdate Model

struct OddsUpdate: Codable, Sendable {
    // MARK: - Properties
    
    let matchID: Int
    let teamAOdds: Double    // 主勝賠率
    let teamBOdds: Double    // 客勝賠率
    let drawOdds: Double?    // 和局賠率（可選，某些運動無和局）
    let timestamp: Date      // 更新時間戳
}
