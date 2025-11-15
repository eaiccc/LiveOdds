//
//  Constants.swift
//  MatchOdd
//
//  Description: Global constants and configuration values for the application
//  
//
//  Created by Link on 2025/11/13.
//

import Foundation
import CoreGraphics

// MARK: - Application Constants

enum Constants {
    // MARK: - API Configuration
    
    enum API {
        /// Base URL for API endpoints
        static let baseURL: String = "https://api.example.com"
        
        /// Matches endpoint path
        static let matchesEndpoint: String = "/matches"
        
        /// Odds endpoint path
        static let oddsEndpoint: String = "/odds"
        
        /// WebSocket URL for real-time updates
        static let wsURL: String = "wss://api.example.com/ws"
    }
    
    // MARK: - UI Configuration
    
    enum UI {
        /// Card corner radius in points
        static let cardCornerRadius: CGFloat = 12
        
        /// Card spacing in points
        static let cardSpacing: CGFloat = 12
        
        /// Standard animation duration in seconds
        static let animationDuration: TimeInterval = 0.3
    }
    
    // MARK: - Cache Configuration
    
    enum Cache {
        /// Cache expiration interval in seconds (5 minutes)
        static let expirationInterval: TimeInterval = 300
        
        /// Quick cache refresh interval in seconds (30 seconds)
        static let quickRefreshInterval: TimeInterval = 30
        
        /// Background update interval in seconds (2 minutes)
        static let backgroundUpdateInterval: TimeInterval = 120
        
        /// Maximum cache age before forced refresh (10 minutes)
        static let maxCacheAge: TimeInterval = 600
        
        /// Number of items to keep in memory cache
        static let maxCachedItems = 100
    }
}
