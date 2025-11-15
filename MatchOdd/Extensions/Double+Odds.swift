//
//  Double+Odds.swift
//  MatchOdd
//
//  Description: Extension providing odds formatting methods for consistent display
//
//  Created by Link on 2025/11/13.
//

import Foundation

// MARK: - Double Odds Extension

extension Double {
    // MARK: - Odds Formatter
    
    /// Shared number formatter for odds display with 2 decimal places
    private static let oddsFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale.current
        return formatter
    }()
    
    // MARK: - Public Methods
    
    /// Formats odds value as string with 2 decimal places
    /// - Returns: Formatted string like "1.85" for odds display
    func toOddsString() -> String {
        return Self.oddsFormatter.string(from: NSNumber(value: self)) ?? String(format: "%.2f", self)
    }
}
