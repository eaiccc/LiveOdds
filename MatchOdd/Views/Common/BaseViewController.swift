//
//  BaseViewController.swift
//  MatchOdd
//
//  Description: Base view controller with centralized loading and error UI management
// 
//
//  Created by Link on 2025/11/13.
//

import UIKit
import SnapKit

// MARK: - BaseViewController

/// Base view controller that provides centralized loading and error UI management
/// Used as a parent class for all view controllers to ensure consistent UX patterns
/// across the application for loading states and error handling
class BaseViewController: UIViewController {
    
    // MARK: - Properties
    
    /// Loading view instance for displaying loading states
    private var loadingView: LoadingView?
    
    /// Error view instance for displaying error states with retry functionality
    private var errorView: ErrorView?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBaseView()
    }
    
    // MARK: - Setup
    
    /// Sets up the base view configuration
    private func setupBaseView() {
        // Set default background color
        view.backgroundColor = .systemBackground
    }
    
    // MARK: - Loading Management
    
    /// Shows a loading indicator overlay on the view controller
    func showLoading() {
        // Hide error view if currently shown
        hideError()
        
        // Create loading view if it doesn't exist
        if loadingView == nil {
            setupLoadingView()
        }
        
        // Show the loading view
        loadingView?.show()
    }
    
    /// Hides the loading indicator overlay
    func hideLoading() {
        loadingView?.hide()
    }
    
    /// Sets up the loading view with proper constraints
    private func setupLoadingView() {
        let loading = LoadingView()

        // Add to view hierarchy
        view.addSubview(loading)

        // Setup constraints to fill the entire view using SnapKit
        loading.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.loadingView = loading
    }
    
    // MARK: - Error Management
    
    /// Shows an error view with a custom message and retry functionality
    /// - Parameters:
    ///   - message: The error message to display to the user
    ///   - onRetry: Closure to execute when the user taps the retry button
    /// - Purpose: Provide consistent error handling with retry capability across all VCs
    func showError(_ message: String, onRetry: @escaping () -> Void) {
        // Hide loading view if currently shown
        hideLoading()
        
        // Create error view if it doesn't exist
        if errorView == nil {
            setupErrorView()
        }
        
        // Configure and show the error view
        errorView?.configure(message: message, retryAction: onRetry)
        errorView?.show(with: message)
    }
    
    /// Hides the error view
    /// - Purpose: Remove error state when retry is successful or navigation occurs
    func hideError() {
        errorView?.hide()
    }
    
    /// Sets up the error view with proper constraints
    /// - Purpose: Initialize and configure error view for the view controller
    private func setupErrorView() {
        let error = ErrorView()

        // Add to view hierarchy
        view.addSubview(error)

        // Setup constraints to fill the safe area using SnapKit
        error.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        self.errorView = error
    }
}

// MARK: - BaseViewController + Convenience

extension BaseViewController {
    
    /// Shows loading with automatic hiding after a specified duration (for testing/demo purposes)
    /// - Parameter duration: Duration in seconds to show loading before auto-hiding
    func showLoadingWithTimeout(duration: TimeInterval = 2.0) {
        showLoading()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.hideLoading()
        }
    }
    
    /// Shows a generic network error with standard retry message
    /// - Parameter onRetry: Closure to execute when retry is tapped
    func showNetworkError(onRetry: @escaping () -> Void) {
        showError("Unable to connect to the network. Please check your connection and try again.", onRetry: onRetry)
    }
    
    /// Shows a generic server error with standard retry message
    /// - Parameter onRetry: Closure to execute when retry is tapped
    func showServerError(onRetry: @escaping () -> Void) {
        showError("Something went wrong on our end. Please try again.", onRetry: onRetry)
    }
}
