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

// MARK: - Application Constants

struct Constants: Sendable {
    // MARK: - API Configuration

    struct API: Sendable {
        /// Base URL for API endpoints
        static let baseURL: String = "https://api.example.com"
        
        /// Matches endpoint path
        static let matchesEndpoint: String = "/matches"
        
        /// Odds endpoint path
        static let oddsEndpoint: String = "/odds"
        
        /// WebSocket URL for real-time updates
        static let wsURL: String = "wss://api.example.com/ws"
    }
    
    // MARK: - Cache Configuration

    struct Cache: Sendable {
        /// Cache expiration interval in seconds (5 minutes)
        static let expirationInterval: Double = 300.0
        
        /// Quick cache refresh interval in seconds (30 seconds)
        static let quickRefreshInterval: Double = 30
        
        /// Background update interval in seconds (2 minutes)
        static let backgroundUpdateInterval: Double = 120
        
        /// Maximum cache age before forced refresh (10 minutes)
        static let maxCacheAge: Double = 600.0
        
        /// Number of items to keep in memory cache
        static let maxCachedItems = 100
    }
}

