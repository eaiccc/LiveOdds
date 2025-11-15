//
//  Date+Formatting.swift
//  MatchOdd
//
//  Description: Extension providing date formatting methods for match times and live match minutes
//
//  Created by Link on 2025/11/13.
//

import Foundation

// MARK: - Date Formatting Extension

extension Date {
    // MARK: - Date Formatters
    
    /// Shared date formatter for match times (MM/dd HH:mm)
    private static let matchTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        formatter.locale = Locale.current
        return formatter
    }()
    
    /// Shared number formatter for live match minutes
    private static let minuteFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    // MARK: - Public Methods
    
    /// Formats date as match time string in "MM/dd HH:mm" format
    /// - Returns: Formatted string like "11/13 18:30"
    /// - Purpose: Display match start times in a compact, readable format
    func toMatchTimeString() -> String {
        return Self.matchTimeFormatter.string(from: self)
    }
    
    /// Formats current minute as live match minute string with apostrophe
    /// - Parameter minute: Current match minute (typically from Match.currentMinute)
    /// - Returns: Formatted string like "45'" for live matches
    /// - Purpose: Display current match progress in live games
    static func toMinuteString(_ minute: Int) -> String {
        guard let formattedMinute = minuteFormatter.string(from: NSNumber(value: minute)) else {
            return "\(minute)'"
        }
        return "\(formattedMinute)'"
    }
}

// MARK: - Convenience Methods

extension Date {
    /// Checks if the date represents a live match (started but not finished)
    /// - Returns: True if the match should be considered live
    /// - Note: Considers matches live if they started within the last 2 hours
    func isLiveMatch() -> Bool {
        let now = Date()
        let twoHoursAgo = now.addingTimeInterval(-7200) // 2 hours = 7200 seconds
        return self > twoHoursAgo && self < now
    }
}
