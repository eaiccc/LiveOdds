//
//  CacheStatistics.swift
//  MatchOdd
//
//  Description: Cache performance monitoring and statistics
//
//  Created by Link on 2025/11/14.
//

import Foundation

// MARK: - Cache Statistics

/// Monitors and tracks cache performance metrics  
final class CacheStatistics: ObservableObject {
    
    // MARK: - Properties
    
    /// Total number of cache requests
    @Published private(set) var totalRequests: Int = 0
    
    /// Number of cache hits
    @Published private(set) var cacheHits: Int = 0
    
    /// Number of cache misses
    @Published private(set) var cacheMisses: Int = 0
    
    /// Cache hit rate as percentage
    var hitRate: Double {
        guard totalRequests > 0 else { return 0.0 }
        return Double(cacheHits) / Double(totalRequests) * 100
    }
    
    /// Last cache update timestamp
    @Published private(set) var lastCacheUpdate: Date?
    
    /// Cache size information
    @Published private(set) var cachedMatchesCount: Int = 0
    @Published private(set) var cachedOddsCount: Int = 0
    
    // MARK: - Public Methods
    
    /// Records a cache hit
    func recordCacheHit() {
        totalRequests += 1
        cacheHits += 1
    }
    
    /// Records a cache miss
    func recordCacheMiss() {
        totalRequests += 1
        cacheMisses += 1
    }
    
    /// Updates cache size information
    /// - Parameters:
    ///   - matchesCount: Number of cached matches
    ///   - oddsCount: Number of cached odds
    func updateCacheSize(matchesCount: Int, oddsCount: Int) {
        cachedMatchesCount = matchesCount
        cachedOddsCount = oddsCount
        lastCacheUpdate = Date()
    }
    
    /// Resets all statistics
    func reset() {
        totalRequests = 0
        cacheHits = 0
        cacheMisses = 0
        cachedMatchesCount = 0
        cachedOddsCount = 0
        lastCacheUpdate = nil
    }
    
    /// Returns formatted statistics string for debugging
    var description: String {
        return """
        Cache Statistics:
        - Total Requests: \(totalRequests)
        - Cache Hits: \(cacheHits)
        - Cache Misses: \(cacheMisses)
        - Hit Rate: \(String(format: "%.1f", hitRate))%
        - Cached Matches: \(cachedMatchesCount)
        - Cached Odds: \(cachedOddsCount)
        - Last Update: \(lastCacheUpdate?.formatted() ?? "Never")
        """
    }
}
