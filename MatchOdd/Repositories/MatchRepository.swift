//
//  MatchRepository.swift
//  MatchOdd
//
//  Description: Repository implementation with caching infrastructure for data access layer
//
//  Created by Link on 2025/11/13.
//

import Foundation

// MARK: - Match Repository Implementation

/// Repository implementation providing data access layer with enhanced caching infrastructure
/// Manages cached matches, odds, cache timestamps, and performance monitoring
actor MatchRepository: MatchRepositoryProtocol {
    // MARK: - Properties
    
    private let networkService: NetworkServicing
    private var cachedMatches: [Match] = []
    private var cachedOdds: [Odds] = []
    private var cacheTimestamp: Date?
    
    // Cache statistics for monitoring performance
    let statistics = CacheStatistics()
    
    // Cache warming flags
    private var isWarmingUp = false
    private var hasWarmedUp = false
    
    // Background update management
    private var lastBackgroundUpdate: Date?
    
    // MARK: - Initialization
    
    /// Initializes the repository with network service dependency injection
    /// - Parameter networkService: The network service for data fetching operations
    init(networkService: NetworkServicing) {
        self.networkService = networkService
        
        // Start cache warming in the background
        Task {
            await warmupCache()
        }
    }
    
    // MARK: - Protocol Implementation
    
    /// Fetches all available matches from the data source
    /// - Returns: An array of Match objects
    /// - Throws: Error if the fetch operation fails
    func fetchMatches() async throws -> [Match] {
        // Check cache validity with smart strategy
        let shouldFetchFromNetwork = checkCacheValidityForMatches()
        
        if !shouldFetchFromNetwork {
            // Record cache hit
            statistics.recordCacheHit()
            
            return cachedMatches
        }
        
        // Record cache miss
        statistics.recordCacheMiss()
        
        // Cache is invalid or empty, fetch from network
        let matches: [Match] = try await networkService.request(.matches)
        
        // Update cache on successful fetch
        updateMatchesCache(matches)
        
        // Update cache statistics
        statistics.updateCacheSize(matchesCount: matches.count, oddsCount: cachedOdds.count)
        
        return matches
    }
    
    /// Checks cache validity for matches and triggers background refresh if needed
    /// - Returns: true if network fetch is needed, false if cached data should be used
    private func checkCacheValidityForMatches() -> Bool {
        if let timestamp = cacheTimestamp {
            let timeSinceCache = Date().timeIntervalSince(timestamp)
            let isEmpty = cachedMatches.isEmpty
            
            // Force refresh if cache is too old
            if timeSinceCache > Constants.Cache.maxCacheAge || isEmpty {
                return true
            }
            
            // Use quick refresh logic for recent data
            let isStale = timeSinceCache > Constants.Cache.quickRefreshInterval
            
            // If data is stale but not too old, trigger background refresh
            if isStale && timeSinceCache < Constants.Cache.expirationInterval {
                // Start background refresh but return cached data
                Task {
                    await backgroundRefresh()
                }
                return false // Use cached data
            }
            
            // Cache is fresh
            let isValid = timeSinceCache < Constants.Cache.expirationInterval && !isEmpty
            return !isValid
        } else {
            return true
        }
    }
    
    /// Updates the matches cache with new data
    /// - Parameter matches: The new matches data to cache
    private func updateMatchesCache(_ matches: [Match]) {
        cachedMatches = matches
        cacheTimestamp = Date()
    }
    
    /// Fetches all available odds from the data source
    /// - Returns: An array of Odds objects
    /// - Throws: Error if the fetch operation fails
    func fetchOdds() async throws -> [Odds] {
        // Check cache validity
        let shouldFetchFromNetwork = checkCacheValidityForOdds()
        
        if !shouldFetchFromNetwork {
            // Record cache hit
            statistics.recordCacheHit()
            
            return cachedOdds
        }
        
        // Record cache miss
        statistics.recordCacheMiss()
        
        // Cache is invalid or empty, fetch from network
        let odds: [Odds] = try await networkService.request(.odds)
        
        // Update cache on successful fetch
        updateOddsCache(odds)
        
        // Update cache statistics
        statistics.updateCacheSize(matchesCount: cachedMatches.count, oddsCount: odds.count)
        
        return odds
    }
    
    /// Checks cache validity for odds
    /// - Returns: true if network fetch is needed, false if cached data should be used
    private func checkCacheValidityForOdds() -> Bool {
        if let timestamp = cacheTimestamp {
            let timeSinceCache = Date().timeIntervalSince(timestamp)
            let isValid = timeSinceCache < Constants.Cache.expirationInterval && !cachedOdds.isEmpty
            return !isValid
        } else {
            return true
        }
    }
    
    /// Updates the odds cache with new data
    /// - Parameter odds: The new odds data to cache
    private func updateOddsCache(_ odds: [Odds]) {
        cachedOdds = odds
        cacheTimestamp = Date()
    }
    
    // MARK: - Cache Management
    
    /// Warms up the cache by pre-loading data in the background
    /// This improves user experience by having data ready when needed
    private func warmupCache() async {
        guard !isWarmingUp && !hasWarmedUp else { return }
        
        isWarmingUp = true
        
        do {
            // Pre-load matches and odds silently
            print("Starting cache warmup...")
            
            async let matchesWarmup = networkService.request(.matches) as [Match]
            async let oddsWarmup = networkService.request(.odds) as [Odds]
            
            let (matches, odds) = try await (matchesWarmup, oddsWarmup)
            
            // Store in cache
            cachedMatches = matches
            cachedOdds = odds
            cacheTimestamp = Date()
            hasWarmedUp = true
            
            // Update statistics
            statistics.updateCacheSize(matchesCount: matches.count, oddsCount: odds.count)
            
            print("Cache warmup completed: \(matches.count) matches, \(odds.count) odds")
            
        } catch {
            print("Cache warmup failed: \(error.localizedDescription)")
        }
        
        isWarmingUp = false
    }
    
    /// Returns whether cache has been warmed up
    var isCacheWarmed: Bool {
        return hasWarmedUp
    }
    
    /// Manually triggers cache refresh
    func refreshCache() async throws {
        cacheTimestamp = nil // Force refresh
        
        // Trigger fresh fetch
        _ = try await fetchMatches()
        _ = try await fetchOdds()
    }
    
    /// Clears all cached data
    func clearCache() async {
        cachedMatches.removeAll()
        cachedOdds.removeAll()
        cacheTimestamp = nil
        hasWarmedUp = false
        
        statistics.reset()
    }
    
    // MARK: - Background Updates
    
    /// Performs background update if needed
    private func performBackgroundUpdate() async {
        guard let lastUpdate = lastBackgroundUpdate else {
            // No previous update, perform one
            await backgroundRefresh()
            return
        }
        
        let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
        if timeSinceLastUpdate >= Constants.Cache.backgroundUpdateInterval {
            await backgroundRefresh()
        }
    }
    
    /// Refreshes cache in background without blocking current requests
    private func backgroundRefresh() async {
        do {
            print("Starting background cache refresh...")
            
            // Fetch fresh data
            async let matchesResult = networkService.request(.matches) as [Match]
            async let oddsResult = networkService.request(.odds) as [Odds]
            
            let (matches, odds) = try await (matchesResult, oddsResult)
            
            // Update cache
            cachedMatches = matches
            cachedOdds = odds
            cacheTimestamp = Date()
            lastBackgroundUpdate = Date()
            
            // Update statistics
            statistics.updateCacheSize(matchesCount: matches.count, oddsCount: odds.count)
            
            print("Background cache refresh completed: \(matches.count) matches, \(odds.count) odds")
            
        } catch {
            print("Background cache refresh failed: \(error.localizedDescription)")
        }
    }
    
}
