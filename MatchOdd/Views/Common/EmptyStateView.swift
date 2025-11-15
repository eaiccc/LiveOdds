//
//  EmptyStateView.swift
//  MatchOdd
//
//  Description: Empty state view with icon and "No matches available" label using SnapKit
//  
//
//  Created by Link on 2025/11/13.
//

import UIKit
import SnapKit

// MARK: - EmptyStateView

/// A view that displays empty state when no matches are available
/// Used to show a friendly message when the match list is empty
final class EmptyStateView: UIView {
    
    // MARK: - Properties
    
    private let containerStackView: UIStackView
    private let iconImageView: UIImageView
    private let messageLabel: UILabel
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        self.containerStackView = UIStackView()
        self.iconImageView = UIImageView()
        self.messageLabel = UILabel()
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = .clear
        
        // Configure subviews
        setupIconImageView()
        setupMessageLabel()
        setupContainerStackView()
        
        // Add subviews
        addSubview(containerStackView)
        
        // Setup layout
        setupLayout()
        
        // Initially hidden
        isHidden = true
    }
    
    private func setupIconImageView() {
        // Use SF Symbols for empty state icon
        let configuration = UIImage.SymbolConfiguration(pointSize: 48, weight: .medium)
        iconImageView.image = UIImage(systemName: "sportscourt.fill", withConfiguration: configuration)
        iconImageView.tintColor = .textSecondary
        iconImageView.contentMode = .scaleAspectFit
        
        // Set fixed size for consistency
        iconImageView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        iconImageView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    }
    
    private func setupMessageLabel() {
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.font = .systemFont(ofSize: 16, weight: .medium)
        messageLabel.textColor = .textSecondary
        messageLabel.text = "No matches available"
        
        // Allow label to expand
        messageLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        messageLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    }
    
    private func setupContainerStackView() {
        containerStackView.axis = .vertical
        containerStackView.alignment = .center
        containerStackView.distribution = .fill
        containerStackView.spacing = 16
        
        // Add subviews to stack view
        containerStackView.addArrangedSubview(iconImageView)
        containerStackView.addArrangedSubview(messageLabel)
    }
    
    private func setupLayout() {
        // Container stack view centered in empty state view
        containerStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(32)
            make.trailing.lessThanOrEqualToSuperview().offset(-32)
        }
        
        // Icon image view fixed size
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(48)
        }
        
        // Message label full width within constraints
        messageLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(containerStackView)
        }
    }
    
    // MARK: - Public Methods
    
    func show(with message: String = "No matches available") {
        messageLabel.text = message
        isHidden = false
        
        // Animate appearance for smooth UX
        alpha = 0.0
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.alpha = 1.0
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0.0
        }) { _ in
            self.isHidden = true
            self.alpha = 1.0
        }
    }
    
    func configure(message: String) {
        messageLabel.text = message
    }
}
