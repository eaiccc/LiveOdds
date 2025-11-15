//
//  UIColor+Theme.swift
//  MatchOdd
//
//  Description: Extension providing semantic color definitions for theme consistency
//
//  Created by Link on 2025/11/13.
//

import UIKit

// MARK: - UIColor Theme Extension

extension UIColor {
    // MARK: - Theme Colors
    
    /// Primary green color for buttons and accents
    static var primaryGreen: UIColor {
        UIColor(named: "ThemePrimaryGreen") ?? .systemGreen
    }
    
    /// Dark background color for main views
    static var backgroundDark: UIColor {
        UIColor(named: "ThemeBackgroundDark") ?? .systemBackground
    }
    
    /// Background color for cards and containers
    static var cardBackground: UIColor {
        UIColor(named: "ThemeCardBackground") ?? .secondarySystemBackground
    }
    
    /// Color for winning odds (green indication)
    static var oddsWin: UIColor {
        UIColor(named: "ThemeOddsWin") ?? .systemGreen
    }
    
    /// Color for draw odds (neutral indication)
    static var oddsDraw: UIColor {
        UIColor(named: "ThemeOddsDraw") ?? .systemYellow
    }
    
    /// Color for losing odds (red indication)
    static var oddsLose: UIColor {
        UIColor(named: "ThemeOddsLose") ?? .systemRed
    }
    
    /// Primary text color
    static var textPrimary: UIColor {
        UIColor(named: "ThemeTextPrimary") ?? .label
    }
    
    /// Secondary text color for subtitles and less important text
    static var textSecondary: UIColor {
        UIColor(named: "ThemeTextSecondary") ?? .secondaryLabel
    }
}
