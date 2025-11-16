//
//  MatchViewData.swift
//  MatchOdd
//
//  Description: View data model combining Match and Odds with animation state tracking for UI updates
//
//  Created by Link on 2025/11/13.
//

import Foundation

// MARK: - MatchViewData Model

/// View data model for match display
/// Must be nonisolated to work with UITableViewDiffableDataSource's Sendable requirements
nonisolated struct MatchViewData: Hashable, Sendable {
    // MARK: - Match Properties
    
    let matchID: Int
    let teamAName: String       // 主隊名稱
    let teamBName: String       // 客隊名稱
    let startTime: Date
    let isLive: Bool            // 比賽是否進行中
    let currentMinute: Int?     // 當前比賽分鐘數
    let scoreA: Int?            // 主隊得分
    let scoreB: Int?            // 客隊得分
    
    // MARK: - Odds Properties
    
    var teamAOdds: Double       // 主勝賠率
    var teamBOdds: Double       // 客勝賠率
    var drawOdds: Double?       // 和局賠率（可選，某些運動無和局）
    
    // MARK: - Animation State Tracking
    
    var teamAOddsDidChange: Bool    // 主勝賠率是否變化
    var teamBOddsDidChange: Bool    // 客勝賠率是否變化
    var drawOddsDidChange: Bool     // 和局賠率是否變化
    
    // MARK: - Hashable Implementation

    func hash(into hasher: inout Hasher) {
        hasher.combine(matchID)
        hasher.combine(teamAName)
        hasher.combine(teamBName)
        hasher.combine(startTime)
        hasher.combine(isLive)
        hasher.combine(currentMinute)
        hasher.combine(scoreA)
        hasher.combine(scoreB)
        hasher.combine(teamAOdds)
        hasher.combine(teamBOdds)
        hasher.combine(drawOdds)
    }

    static func == (lhs: MatchViewData, rhs: MatchViewData) -> Bool {
        return lhs.matchID == rhs.matchID &&
               lhs.teamAName == rhs.teamAName &&
               lhs.teamBName == rhs.teamBName &&
               lhs.startTime == rhs.startTime &&
               lhs.isLive == rhs.isLive &&
               lhs.currentMinute == rhs.currentMinute &&
               lhs.scoreA == rhs.scoreA &&
               lhs.scoreB == rhs.scoreB &&
               lhs.teamAOdds == rhs.teamAOdds &&
               lhs.teamBOdds == rhs.teamBOdds &&
               lhs.drawOdds == rhs.drawOdds
    }
}

// MARK: - Factory Methods

extension MatchViewData {
    /// 從 Match 和 Odds 模型創建 MatchViewData
    /// - Parameters:
    ///   - match: Match 模型
    ///   - odds: Odds 模型
    ///   - previousOdds: 先前的賠率（用於變化檢測）
    /// - Returns: MatchViewData 實例
    static func create(
        from match: Match,
        odds: Odds,
        previousOdds: Odds? = nil
    ) -> MatchViewData {
        let teamAChanged = previousOdds?.teamAOdds != odds.teamAOdds
        let teamBChanged = previousOdds?.teamBOdds != odds.teamBOdds
        let drawChanged = previousOdds?.drawOdds != odds.drawOdds
        
        return MatchViewData(
            matchID: match.matchID,
            teamAName: match.teamA,
            teamBName: match.teamB,
            startTime: match.startTime,
            isLive: match.isLive,
            currentMinute: match.currentMinute,
            scoreA: match.scoreA,
            scoreB: match.scoreB,
            teamAOdds: odds.teamAOdds,
            teamBOdds: odds.teamBOdds,
            drawOdds: odds.drawOdds,
            teamAOddsDidChange: teamAChanged,
            teamBOddsDidChange: teamBChanged,
            drawOddsDidChange: drawChanged
        )
    }
    
    /// 從現有 MatchViewData 更新賠率
    /// - Parameters:
    ///   - newOdds: 新的賠率
    /// - Returns: 更新後的 MatchViewData 實例
    func updatingOdds(_ newOdds: Odds) -> MatchViewData {
        let teamAChanged = self.teamAOdds != newOdds.teamAOdds
        let teamBChanged = self.teamBOdds != newOdds.teamBOdds
        let drawChanged = self.drawOdds != newOdds.drawOdds
        
        return MatchViewData(
            matchID: self.matchID,
            teamAName: self.teamAName,
            teamBName: self.teamBName,
            startTime: self.startTime,
            isLive: self.isLive,
            currentMinute: self.currentMinute,
            scoreA: self.scoreA,
            scoreB: self.scoreB,
            teamAOdds: newOdds.teamAOdds,
            teamBOdds: newOdds.teamBOdds,
            drawOdds: newOdds.drawOdds,
            teamAOddsDidChange: teamAChanged,
            teamBOddsDidChange: teamBChanged,
            drawOddsDidChange: drawChanged
        )
    }
}
