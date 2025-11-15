//
//  MatchListViewController.swift
//  MatchOdd
//
//  Description: Main view controller for displaying match list with table view and real-time odds updates
//  @MainActor for UI thread safety
//
//  Created by Link on 2025/11/13.
//

import UIKit
import Combine
import SnapKit

enum Section: Hashable, Sendable {
    case main
}

// MARK: - MatchListViewController

/// Main view controller for displaying a list of matches with real-time odds updates
/// Uses table view with diffable data source for smooth animations and updates
/// Inherits from BaseViewController for centralized loading and error management
/// Swift 6 @MainActor ensures all UI updates happen on the main thread
@MainActor
final class MatchListViewController: BaseViewController {
    
    // MARK: - Properties
    
    /// View model managing match data and real-time odds updates
    /// Handles data fetching, state management, and business logic
    private let viewModel: MatchListViewModel

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .systemBackground
        tv.separatorStyle = .none
        tv.estimatedRowHeight = 120
        tv.rowHeight = UITableView.automaticDimension
        tv.delegate = self
        tv.showsVerticalScrollIndicator = true
        tv.alwaysBounceVertical = true
        
        // Register cell type
        tv.register(MatchTableViewCell.self, forCellReuseIdentifier: String(describing: MatchTableViewCell.self))
        
        return tv
    }()
    

    private var dataSource: UITableViewDiffableDataSource<Section, MatchViewData>!
    
    /// View state manager for preserving scroll position and selection
    /// Enables quick restoration of user's browsing state
    private let stateManager = ViewStateManager()
    
    // MARK: - Initialization
    
    init(viewModel: MatchListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDataSource()
        setupBindings()
        Task {
            await viewModel.loadInitialData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Restore saved state after view appears and data is loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.restoreViewState()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Save current state before leaving the view
        saveCurrentViewState()
    }
    
    // MARK: - Private Setup Methods
    
    private func setupUI() {
        setupNavigationBar()
        setupViewHierarchy()
        setupConstraints()
        configureTableViewAppearance()
    }
    
    private func setupNavigationBar() {
        title = "LiveOdds"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        // Create animation toggle button
        let animationButton = UIBarButtonItem(
            image: UIImage(systemName: "sparkles"),
            style: .plain,
            target: self,
            action: #selector(animationToggleTapped)
        )
        animationButton.tintColor = .primaryGreen
        
        #if DEBUG
        // Add disconnect simulation button (debug only)
        let disconnectButton = UIBarButtonItem(
            image: UIImage(systemName: "wifi.slash"),
            style: .plain,
            target: self,
            action: #selector(simulateDisconnectTapped)
        )
        disconnectButton.tintColor = .systemRed
        
        // Set both buttons in navigation bar
        navigationItem.rightBarButtonItems = [disconnectButton, animationButton]
        #else
        // Production: only animation toggle
        navigationItem.rightBarButtonItem = animationButton
        #endif
    }
    
    private func setupViewHierarchy() {
        view.backgroundColor = .systemBackground
        
        // Add table view to view hierarchy
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func configureTableViewAppearance() {
        // Enhanced scroll behavior
        tableView.contentInsetAdjustmentBehavior = .automatic
        tableView.scrollIndicatorInsets = .zero
        
        // Performance optimizations
        tableView.prefetchDataSource = nil // Disable prefetching for consistent performance
        tableView.dragInteractionEnabled = false
        
        // Enhanced visual appearance
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        // Accessibility improvements
        tableView.accessibilityLabel = "Match list"
        tableView.accessibilityHint = "Scrollable list of matches with live odds"
    }

    @objc private func simulateDisconnectTapped() {
        print("User triggered disconnection simulation")
        viewModel.simulateDisconnection()
    }
    
    @objc private func animationToggleTapped() {
        viewModel.toggleAnimations()
        updateAnimationButtonState()
    }
    
    private func setupDataSource() {
        dataSource = UITableViewDiffableDataSource<Section, MatchViewData>(
            tableView: tableView
        ) { [weak self] (tableView: UITableView, indexPath: IndexPath, matchViewData: MatchViewData) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(
                withIdentifier: String(describing: MatchTableViewCell.self),
                for: indexPath
            ) as! MatchTableViewCell
            
            // Configure cell with match data and animation settings
            let animationsEnabled = self?.viewModel.animationsEnabled ?? true
            cell.configure(with: matchViewData, animationsEnabled: animationsEnabled)
            
            return cell
        }
    }
    
    private func setupBindings() {
        // Observe matches data changes
        viewModel.$matches.receive(on: DispatchQueue.main)
            .sink { [weak self] matches in
                self?.updateDataSource(with: matches)
            }
            .store(in: &cancellables)
        
        // Observe loading state changes
        viewModel.$isLoading.receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.showLoading()
                } else {
                    self?.hideLoading()
                }
            }
            .store(in: &cancellables)
        
        // Observe error state changes
        viewModel.$error.receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.showError(error.localizedDescription) { [weak self] in
                        self?.loadData()
                    }
                } else {
                    self?.hideError()
                }
            }
            .store(in: &cancellables)

        // Observe connection state changes
        viewModel.$connectionState.receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateConnectionIndicator(state: state)
            }
            .store(in: &cancellables)
        
        // Observe animation settings changes
        viewModel.$animationsEnabled.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAnimationButtonState()
            }
            .store(in: &cancellables)
    }

    /// Updates the navigation bar item to reflect connection state
    /// - Parameter state: Current connection state
    private func updateConnectionIndicator(state: ConnectionState) {
        #if DEBUG
        let (image, color) = connectionIndicator(for: state)
        let disconnectButton = UIBarButtonItem(
            image: image,
            style: .plain,
            target: self,
            action: #selector(simulateDisconnectTapped)
        )
        disconnectButton.tintColor = color
        
        // Keep animation button alongside connection indicator
        let animationButton = UIBarButtonItem(
            image: UIImage(systemName: viewModel.animationsEnabled ? "sparkles" : "sparkles.rectangle.stack"),
            style: .plain,
            target: self,
            action: #selector(animationToggleTapped)
        )
        animationButton.tintColor = viewModel.animationsEnabled ? .primaryGreen : .systemGray
        
        navigationItem.rightBarButtonItems = [disconnectButton, animationButton]
        #endif
    }
    
    /// Updates animation button appearance based on current state
    private func updateAnimationButtonState() {
        let symbolName = viewModel.animationsEnabled ? "sparkles" : "sparkles.rectangle.stack"
        let color: UIColor = viewModel.animationsEnabled ? .primaryGreen : .systemGray
        
        #if DEBUG
        // Update the animation button in the existing right bar button items
        if let rightBarButtonItems = navigationItem.rightBarButtonItems,
           rightBarButtonItems.count > 1 {
            let animationButton = rightBarButtonItems[1]
            animationButton.image = UIImage(systemName: symbolName)
            animationButton.tintColor = color
        }
        #else
        // Production: update the single animation button
        navigationItem.rightBarButtonItem?.image = UIImage(systemName: symbolName)
        navigationItem.rightBarButtonItem?.tintColor = color
        #endif
    }

    /// Returns appropriate SF Symbol and color for connection state
    /// - Parameter state: Connection state
    /// - Returns: Tuple of UIImage and UIColor
    private func connectionIndicator(for state: ConnectionState) -> (UIImage?, UIColor) {
        switch state {
        case .disconnected:
            title = "LiveOdds"
            return (UIImage(systemName: "wifi.slash"), .systemRed)
        case .connecting:
            title = "LiveOdds"
            return (UIImage(systemName: "wifi.exclamationmark"), .systemOrange)
        case .connected:
            title = "LiveOdds"
            return (UIImage(systemName: "wifi"), .systemGreen)
        case .reconnecting(let attempt):
            title = "LiveOdds (Reconnecting \(attempt)/5)"
            return (UIImage(systemName: "arrow.clockwise"), .systemOrange)
        }
    }
    
    /// Applies a snapshot with the provided matches to the data source
    private func applySnapshot(_ matches: [MatchViewData]) {
        // Create new snapshot for UITableViewDiffableDataSource
        var snapshot = NSDiffableDataSourceSnapshot<Section, MatchViewData>()
        snapshot.appendSections([Section.main])
        snapshot.appendItems(matches, toSection: Section.main)

        // Performance optimization: Apply without animations for 60 FPS target
        // This ensures smooth scrolling with 100+ matches and real-time updates
        dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
    }
    
    /// Updates the data source with new match data using UITableViewDiffableDataSource
    private func updateDataSource(with matches: [MatchViewData]) {
        // Ensure updates happen on main thread for UI safety
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.updateDataSource(with: matches)
            }
            return
        }
        
        // Apply snapshot using our optimized method
        applySnapshot(matches)
    }
    
    private func loadData() {
        Task {
            await viewModel.loadInitialData()
        }
    }
    
    
    // MARK: - Properties for Combine
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - View State Management
    
    /// Saves the current view state for restoration
    private func saveCurrentViewState() {
        saveTableViewScrollPosition()
    }
    
    /// Restores the saved view state
    private func restoreViewState() {
        restoreTableViewScrollPosition()
    }
    
    /// Saves the current tableView scroll position and visible content to ViewStateManager
    /// - Purpose: Persist user's browsing position for quick restoration with enhanced UITableView support
    /// - Performance: Optimized to capture minimal state data efficiently with bounds validation
    private func saveTableViewScrollPosition() {
        // Use enhanced ViewStateManager method with automatic bounds validation
        stateManager.saveTableViewState(tableView)
        print("TableView state saved using enhanced ViewStateManager")
    }
    
    /// Restores the saved tableView scroll position from ViewStateManager
    /// - Purpose: Restore user's browsing position seamlessly after app backgrounding/foregrounding
    /// - Performance: Smooth animated restoration within 10 points accuracy target using enhanced bounds validation
    private func restoreTableViewScrollPosition() {
        // Use enhanced ViewStateManager method with automatic bounds validation and smooth animation
        let restored = stateManager.restoreTableViewState(tableView)
        if restored {
            print("TableView state restored using enhanced ViewStateManager")
        } else {
            print("No tableView state to restore")
        }
    }
}

// MARK: - UITableViewDelegate

extension MatchListViewController: UITableViewDelegate {
    
    /// Table view delegate implementation for handling user interactions
    /// Currently provides placeholder for future item selection handling
    /// - Purpose: Handle user taps and interactions with match items
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Update selected match in state manager
        if indexPath.row < viewModel.matches.count {
            let selectedMatch = viewModel.matches[indexPath.row]
            stateManager.updateSelectedMatch(selectedMatch.matchID)
        }
        
        // TODO: Handle match selection for detailed view navigation
    }
    
    /// Tracks scroll position changes for state preservation
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Throttle state saving to avoid too frequent updates
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateScrollState), object: nil)
        perform(#selector(updateScrollState), with: nil, afterDelay: 0.1)
    }
    
    @objc private func updateScrollState() {
        // Use enhanced scroll position update with current content bounds
        stateManager.updateScrollPosition(
            tableView.contentOffset,
            contentSize: tableView.contentSize,
            viewBounds: tableView.bounds.size
        )
    }
}
