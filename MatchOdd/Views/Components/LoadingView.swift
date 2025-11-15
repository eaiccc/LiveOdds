//
//  LoadingView.swift
//  MatchOdd
//
//  Description: Loading view with semi-transparent background and activity indicator
// 
//
//  Created by Link on 2025/11/13.
//

import UIKit
import SnapKit

// MARK: - LoadingView

/// A loading view that displays an activity indicator over a semi-transparent background
/// Used to indicate data loading states throughout the application
final class LoadingView: UIView {
    
    // MARK: - Properties
    
    private let activityIndicator: UIActivityIndicatorView
    private let backgroundView: UIView
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        self.activityIndicator = UIActivityIndicatorView(style: .large)
        self.backgroundView = UIView()
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupView() {
        // Configure background view
        setupBackgroundView()
        
        // Configure activity indicator
        setupActivityIndicator()
        
        // Add subviews
        addSubview(backgroundView)
        addSubview(activityIndicator)
        
        // Setup layout
        setupLayout()
        
        // Initially hidden
        isHidden = true
    }
    
    private func setupBackgroundView() {
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
    }

    private func setupActivityIndicator() {
        activityIndicator.style = .large
        activityIndicator.color = .primaryGreen
        activityIndicator.hidesWhenStopped = false
    }

    private func setupLayout() {
        // Background view fills entire loading view
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Activity indicator centered in view
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    // MARK: - Public Methods
    
    func show() {
        isHidden = false
        activityIndicator.startAnimating()
        
        // Animate appearance for smooth UX
        alpha = 0.0
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1.0
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0.0
        }) { _ in
            self.isHidden = true
            self.activityIndicator.stopAnimating()
            self.alpha = 1.0
        }
    }
}
