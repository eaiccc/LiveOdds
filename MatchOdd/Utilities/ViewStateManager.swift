//
//  ViewStateManager.swift
//  MatchOdd
//
//  Description: Manages view state persistence for UITableView with scroll position and selection restoration
//  Updated for full UITableView compatibility
//
//  Created by Link on 2025/11/14.
//

import Foundation
import UIKit

// MARK: - View State Data

/// Stores view state information for restoration with enhanced UITableView support
struct ViewState: Codable {
    let scrollPosition: CGPoint
    let selectedMatchID: Int?
    let lastUpdateTime: Date
    let visibleIndexes: [Int]
    
    /// Content offset bounds for validation
    let contentSize: CGSize
    let viewBounds: CGSize
    
    /// Enhanced initializer with bounds validation for UITableView compatibility
    init(
        scrollPosition: CGPoint = .zero,
        selectedMatchID: Int? = nil,
        visibleIndexes: [Int] = [],
        contentSize: CGSize = .zero,
        viewBounds: CGSize = .zero
    ) {
        self.scrollPosition = scrollPosition
        self.selectedMatchID = selectedMatchID
        self.lastUpdateTime = Date()
        self.visibleIndexes = visibleIndexes
        self.contentSize = contentSize
        self.viewBounds = viewBounds
    }
}

// MARK: - View State Manager

/// Manages persistence and restoration of view states with enhanced UITableView support
/// Provides robust scroll position management, selection persistence, and bounds validation
/// Compatible with both UICollectionView and UITableView through UIScrollView protocol
@MainActor
final class ViewStateManager: ObservableObject {
    
    // MARK: - Properties
    
    private let userDefaults = UserDefaults.standard
    private let stateKey = "MatchList.ViewState"
    
    /// Currently saved view state
    @Published private(set) var currentState: ViewState?
    
    /// Whether state restoration is enabled
    @Published var isStateRestorationEnabled: Bool = true {
        didSet {
            userDefaults.set(isStateRestorationEnabled, forKey: "StateRestorationEnabled")
        }
    }
    
    // MARK: - Initialization
    
    init() {
        isStateRestorationEnabled = userDefaults.bool(forKey: "StateRestorationEnabled")
        currentState = loadSavedState()
    }
    
    // MARK: - Public Methods
    
    /// Saves the current view state with enhanced UITableView support
    /// - Parameters:
    ///   - scrollPosition: Current scroll position of the table view or collection view
    ///   - selectedMatchID: Currently selected match ID (if any)
    ///   - visibleIndexes: Currently visible item indexes
    ///   - contentSize: Current content size for bounds validation
    ///   - viewBounds: Current view bounds for restoration validation
    func saveViewState(
        scrollPosition: CGPoint,
        selectedMatchID: Int? = nil,
        visibleIndexes: [Int] = [],
        contentSize: CGSize = .zero,
        viewBounds: CGSize = .zero
    ) {
        guard isStateRestorationEnabled else { return }
        
        // Validate scroll position bounds before saving
        let validatedScrollPosition = validateScrollPosition(
            scrollPosition,
            contentSize: contentSize,
            viewBounds: viewBounds
        )
        
        let state = ViewState(
            scrollPosition: validatedScrollPosition,
            selectedMatchID: selectedMatchID,
            visibleIndexes: visibleIndexes,
            contentSize: contentSize,
            viewBounds: viewBounds
        )
        
        currentState = state
        
        do {
            let data = try JSONEncoder().encode(state)
            userDefaults.set(data, forKey: stateKey)
            print("View state saved: scroll(\(validatedScrollPosition.x), \(validatedScrollPosition.y)), content(\(contentSize.width), \(contentSize.height))")
        } catch {
            print("Failed to save view state: \(error)")
        }
    }
    
    /// Legacy method for backward compatibility - will be deprecated
    /// - Parameters:
    ///   - scrollPosition: Current scroll position
    ///   - selectedMatchID: Currently selected match ID (if any)  
    ///   - visibleIndexes: Currently visible item indexes
    func saveViewState(
        scrollPosition: CGPoint,
        selectedMatchID: Int? = nil,
        visibleIndexes: [Int] = []
    ) {
        saveViewState(
            scrollPosition: scrollPosition,
            selectedMatchID: selectedMatchID,
            visibleIndexes: visibleIndexes,
            contentSize: .zero,
            viewBounds: .zero
        )
    }
    
    /// Loads the saved view state with enhanced validation for UITableView compatibility
    /// - Returns: The saved view state, or nil if none exists or is invalid
    func loadSavedState() -> ViewState? {
        guard isStateRestorationEnabled else { return nil }
        
        guard let data = userDefaults.data(forKey: stateKey) else {
            print("No saved view state found")
            return nil
        }
        
        do {
            let state = try JSONDecoder().decode(ViewState.self, from: data)
            
            // Check if state is not too old (max 1 hour)
            let timeInterval = Date().timeIntervalSince(state.lastUpdateTime)
            guard timeInterval < 3600 else { // 1 hour
                print("Saved view state is too old, ignoring")
                clearSavedState()
                return nil
            }
            
            currentState = state
            print("View state loaded: scroll(\(state.scrollPosition.x), \(state.scrollPosition.y)), content(\(state.contentSize.width), \(state.contentSize.height))")
            return state
            
        } catch {
            print("Failed to load view state: \(error)")
            // Handle potential migration from old ViewState format
            handleStateMigration()
            return nil
        }
    }
    
    /// Handles migration from legacy ViewState format to new enhanced format
    private func handleStateMigration() {
        print("Attempting to migrate legacy view state format")
        // Clear old incompatible state - users will start fresh
        clearSavedState()
    }
    
    /// Clears the saved view state
    func clearSavedState() {
        currentState = nil
        userDefaults.removeObject(forKey: stateKey)
        print("View state cleared")
    }
    
    /// Updates only the scroll position of the current state with bounds validation
    /// - Parameters:
    ///   - scrollPosition: New scroll position to save
    ///   - contentSize: Optional content size for validation (uses cached if not provided)
    ///   - viewBounds: Optional view bounds for validation (uses cached if not provided)
    func updateScrollPosition(
        _ scrollPosition: CGPoint,
        contentSize: CGSize? = nil,
        viewBounds: CGSize? = nil
    ) {
        guard isStateRestorationEnabled else { return }
        
        let currentContentSize = contentSize ?? currentState?.contentSize ?? .zero
        let currentViewBounds = viewBounds ?? currentState?.viewBounds ?? .zero
        
        saveViewState(
            scrollPosition: scrollPosition,
            selectedMatchID: currentState?.selectedMatchID,
            visibleIndexes: currentState?.visibleIndexes ?? [],
            contentSize: currentContentSize,
            viewBounds: currentViewBounds
        )
    }
    
    /// Updates the selected match ID while preserving other state
    /// - Parameter matchID: The ID of the selected match
    func updateSelectedMatch(_ matchID: Int?) {
        guard isStateRestorationEnabled else { return }
        
        saveViewState(
            scrollPosition: currentState?.scrollPosition ?? .zero,
            selectedMatchID: matchID,
            visibleIndexes: currentState?.visibleIndexes ?? [],
            contentSize: currentState?.contentSize ?? .zero,
            viewBounds: currentState?.viewBounds ?? .zero
        )
    }
    
    /// Returns whether there is a valid saved state to restore
    var hasValidSavedState: Bool {
        return currentState != nil
    }
    
    /// Returns a debug description of the current state
    var stateDescription: String {
        guard let state = currentState else {
            return "No saved state"
        }
        
        return """
        View State:
        - Scroll Position: (\(state.scrollPosition.x), \(state.scrollPosition.y))
        - Content Size: (\(state.contentSize.width), \(state.contentSize.height))
        - View Bounds: (\(state.viewBounds.width), \(state.viewBounds.height))
        - Selected Match: \(state.selectedMatchID?.description ?? "None")
        - Visible Indexes: \(state.visibleIndexes)
        - Last Update: \(state.lastUpdateTime.formatted())
        """
    }
    
    // MARK: - UITableView Specific Helpers
    
    /// Convenience method to save UITableView state with proper bounds validation
    /// - Parameter tableView: The UITableView instance to save state for
    func saveTableViewState(_ tableView: UITableView) {
        let scrollPosition = tableView.contentOffset
        let visibleIndexPaths = tableView.indexPathsForVisibleRows ?? []
        let visibleIndexes = visibleIndexPaths.map { $0.row }
        let contentSize = tableView.contentSize
        let viewBounds = tableView.bounds.size
        
        saveViewState(
            scrollPosition: scrollPosition,
            selectedMatchID: currentState?.selectedMatchID,
            visibleIndexes: visibleIndexes,
            contentSize: contentSize,
            viewBounds: viewBounds
        )
    }
    
    /// Convenience method to restore UITableView state with smooth animation
    /// - Parameter tableView: The UITableView instance to restore state for
    /// - Returns: Whether restoration was successful
    @discardableResult
    func restoreTableViewState(_ tableView: UITableView) -> Bool {
        guard let savedState = loadSavedState() else {
            print("No tableView scroll position to restore")
            return false
        }
        
        // Validate that the saved position is still valid for current content
        let contentSize = tableView.contentSize
        let tableViewBounds = tableView.bounds
        
        let validatedPosition = validateScrollPosition(
            savedState.scrollPosition,
            contentSize: contentSize,
            viewBounds: tableViewBounds.size
        )
        
        // Restore scroll position with smooth animation for better UX
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            tableView.setContentOffset(validatedPosition, animated: false)
        }, completion: { _ in
            print("TableView scroll position restored: (\(validatedPosition.x), \(validatedPosition.y))")
        })
        
        return true
    }
    
    /// Convenience method to save UICollectionView state for backward compatibility
    /// - Parameter collectionView: The UICollectionView instance to save state for
    func saveCollectionViewState(_ collectionView: UICollectionView) {
        let scrollPosition = collectionView.contentOffset
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        let visibleIndexes = visibleIndexPaths.map { $0.item }
        let contentSize = collectionView.contentSize
        let viewBounds = collectionView.bounds.size
        
        saveViewState(
            scrollPosition: scrollPosition,
            selectedMatchID: currentState?.selectedMatchID,
            visibleIndexes: visibleIndexes,
            contentSize: contentSize,
            viewBounds: viewBounds
        )
    }
    
    /// Convenience method to restore UICollectionView state for backward compatibility
    /// - Parameter collectionView: The UICollectionView instance to restore state for
    /// - Returns: Whether restoration was successful
    @discardableResult
    func restoreCollectionViewState(_ collectionView: UICollectionView) -> Bool {
        guard let savedState = loadSavedState() else {
            print("No collectionView scroll position to restore")
            return false
        }
        
        let contentSize = collectionView.contentSize
        let collectionViewBounds = collectionView.bounds
        
        let validatedPosition = validateScrollPosition(
            savedState.scrollPosition,
            contentSize: contentSize,
            viewBounds: collectionViewBounds.size
        )
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            collectionView.setContentOffset(validatedPosition, animated: false)
        }, completion: { _ in
            print("CollectionView scroll position restored: (\(validatedPosition.x), \(validatedPosition.y))")
        })
        
        return true
    }
    
    // MARK: - Private Helpers
    
    /// Validates and clamps scroll position to valid bounds
    /// - Parameters:
    ///   - scrollPosition: The scroll position to validate
    ///   - contentSize: The content size for bounds checking
    ///   - viewBounds: The view bounds for bounds checking
    /// - Returns: A validated scroll position within proper bounds
    private func validateScrollPosition(
        _ scrollPosition: CGPoint,
        contentSize: CGSize,
        viewBounds: CGSize
    ) -> CGPoint {
        let maxX = max(0, contentSize.width - viewBounds.width)
        let maxY = max(0, contentSize.height - viewBounds.height)
        
        return CGPoint(
            x: max(0, min(scrollPosition.x, maxX)),
            y: max(0, min(scrollPosition.y, maxY))
        )
    }
}
