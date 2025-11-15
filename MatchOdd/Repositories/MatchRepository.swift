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
final class MatchRepository: MatchRepositoryProtocol, @unchecked Sendable {
    // MARK: - Properties
    
    private let networkService: NetworkServicing
    private var cachedMatches: [Match] = []
    private var cachedOdds: [Odds] = []
    private var cacheTimestamp: Date?
    
    // Private queue for thread-safe access to cached data
    private let cacheQueue = DispatchQueue(label: "com.matchodd.repository.cache", attributes: .concurrent)
    
    // Cache statistics for monitoring performance
    let statistics = CacheStatistics()
    
    // Cache warming flags
    private var isWarmingUp = false
    private var hasWarmedUp = false
    
    // Background update management
    private var backgroundUpdateTimer: Timer?
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
        
        // Start background update timer
        startBackgroundUpdates()
    }
    
    deinit {
        backgroundUpdateTimer?.invalidate()
    }
    
    // MARK: - Protocol Implementation
    
    /// Fetches all available matches from the data source
    /// - Returns: An array of Match objects
    /// - Throws: Error if the fetch operation fails
    func fetchMatches() async throws -> [Match] {
        // Check cache validity with smart strategy
        let shouldFetchFromNetwork = await withCheckedContinuation { continuation in
            cacheQueue.async {
                if let timestamp = self.cacheTimestamp {
                    let timeSinceCache = Date().timeIntervalSince(timestamp)
                    let isEmpty = self.cachedMatches.isEmpty
                    
                    // Force refresh if cache is too old
                    if timeSinceCache > Constants.Cache.maxCacheAge || isEmpty {
                        continuation.resume(returning: true)
                        return
                    }
                    
                    // Use quick refresh logic for recent data
                    let isStale = timeSinceCache > Constants.Cache.quickRefreshInterval
                    
                    // If data is stale but not too old, trigger background refresh
                    if isStale && timeSinceCache < Constants.Cache.expirationInterval {
                        // Start background refresh but return cached data
                        Task {
                            await self.backgroundRefresh()
                        }
                        continuation.resume(returning: false) // Use cached data
                        return
                    }
                    
                    // Cache is fresh
                    let isValid = timeSinceCache < Constants.Cache.expirationInterval && !isEmpty
                    continuation.resume(returning: !isValid)
                } else {
                    continuation.resume(returning: true)
                }
            }
        }
        
        if !shouldFetchFromNetwork {
            // Record cache hit
            await MainActor.run {
                statistics.recordCacheHit()
            }
            
            return await withCheckedContinuation { continuation in
                cacheQueue.async {
                    continuation.resume(returning: self.cachedMatches)
                }
            }
        }
        
        // Record cache miss
        await MainActor.run {
            statistics.recordCacheMiss()
        }
        
        // Cache is invalid or empty, fetch from network
        let matches: [Match] = try await networkService.request(.matches)
        
        // Update cache on successful fetch in a thread-safe manner
        await withCheckedContinuation { continuation in
            cacheQueue.async(flags: .barrier) {
                self.cachedMatches = matches
                self.cacheTimestamp = Date()
                continuation.resume()
            }
        }
        
        // Update cache statistics
        await MainActor.run {
            statistics.updateCacheSize(matchesCount: matches.count, oddsCount: cachedOdds.count)
        }
        
        return matches
    }
    
    /// Fetches all available odds from the data source
    /// - Returns: An array of Odds objects
    /// - Throws: Error if the fetch operation fails
    func fetchOdds() async throws -> [Odds] {
        // Check cache validity in a thread-safe manner
        let shouldFetchFromNetwork = await withCheckedContinuation { continuation in
            cacheQueue.async {
                if let timestamp = self.cacheTimestamp {
                    let timeSinceCache = Date().timeIntervalSince(timestamp)
                    let isValid = timeSinceCache < Constants.Cache.expirationInterval && !self.cachedOdds.isEmpty
                    continuation.resume(returning: !isValid)
                } else {
                    continuation.resume(returning: true)
                }
            }
        }
        
        if !shouldFetchFromNetwork {
            // Record cache hit
            await MainActor.run {
                statistics.recordCacheHit()
            }
            
            return await withCheckedContinuation { continuation in
                cacheQueue.async {
                    continuation.resume(returning: self.cachedOdds)
                }
            }
        }
        
        // Record cache miss
        await MainActor.run {
            statistics.recordCacheMiss()
        }
        
        // Cache is invalid or empty, fetch from network
        let odds: [Odds] = try await networkService.request(.odds)
        
        // Update cache on successful fetch in a thread-safe manner
        await withCheckedContinuation { continuation in
            cacheQueue.async(flags: .barrier) {
                self.cachedOdds = odds
                self.cacheTimestamp = Date()
                continuation.resume()
            }
        }
        
        // Update cache statistics
        await MainActor.run {
            statistics.updateCacheSize(matchesCount: cachedMatches.count, oddsCount: odds.count)
        }
        
        return odds
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
            await withCheckedContinuation { continuation in
                cacheQueue.async(flags: .barrier) {
                    self.cachedMatches = matches
                    self.cachedOdds = odds
                    self.cacheTimestamp = Date()
                    self.hasWarmedUp = true
                    continuation.resume()
                }
            }
            
            // Update statistics
            await MainActor.run {
                statistics.updateCacheSize(matchesCount: matches.count, oddsCount: odds.count)
            }
            
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
        await withCheckedContinuation { continuation in
            cacheQueue.async(flags: .barrier) {
                self.cacheTimestamp = nil // Force refresh
                continuation.resume()
            }
        }
        
        // Trigger fresh fetch
        _ = try await fetchMatches()
        _ = try await fetchOdds()
    }
    
    /// Clears all cached data
    func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.cachedMatches.removeAll()
            self.cachedOdds.removeAll()
            self.cacheTimestamp = nil
            self.hasWarmedUp = false
        }
        
        statistics.reset()
    }
    
    // MARK: - Background Updates
    
    /// Starts periodic background updates
    private func startBackgroundUpdates() {
        backgroundUpdateTimer = Timer.scheduledTimer(withTimeInterval: Constants.Cache.backgroundUpdateInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.performBackgroundUpdate()
            }
        }
    }
    
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
            
            // Update cache in background
            await withCheckedContinuation { continuation in
                cacheQueue.async(flags: .barrier) {
                    self.cachedMatches = matches
                    self.cachedOdds = odds
                    self.cacheTimestamp = Date()
                    self.lastBackgroundUpdate = Date()
                    continuation.resume()
                }
            }
            
            // Update statistics
            await MainActor.run {
                statistics.updateCacheSize(matchesCount: matches.count, oddsCount: odds.count)
            }
            
            print("Background cache refresh completed: \(matches.count) matches, \(odds.count) odds")
            
        } catch {
            print("Background cache refresh failed: \(error.localizedDescription)")
        }
    }
    
    /// Enables/disables background updates
    func setBackgroundUpdatesEnabled(_ enabled: Bool) {
        if enabled {
            if backgroundUpdateTimer == nil {
                startBackgroundUpdates()
            }
        } else {
            backgroundUpdateTimer?.invalidate()
            backgroundUpdateTimer = nil
        }
    }
}
