//
//  ErrorView.swift
//  MatchOdd
//
//  Description: Error view with error icon, message label, and retry button using SnapKit
// 
//
//  Created by Link on 2025/11/13.
//

import UIKit
import SnapKit

// MARK: - ErrorView

/// A view that displays error states with an icon, message, and retry functionality
/// Used throughout the application to show error conditions with recovery options
final class ErrorView: UIView {
    
    // MARK: - Properties
    
    private let containerStackView: UIStackView
    private let iconImageView: UIImageView
    private let messageLabel: UILabel
    private let retryButton: UIButton
    
    /// Closure called when the retry button is tapped
    var onRetry: (() -> Void)?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        self.containerStackView = UIStackView()
        self.iconImageView = UIImageView()
        self.messageLabel = UILabel()
        self.retryButton = UIButton(type: .system)
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
        setupRetryButton()
        setupContainerStackView()
        
        // Add subviews
        addSubview(containerStackView)
        
        // Setup layout
        setupLayout()
        
        // Initially hidden
        isHidden = true
    }
    
    private func setupIconImageView() {
        // Use SF Symbols for error icon
        let configuration = UIImage.SymbolConfiguration(pointSize: 48, weight: .medium)
        iconImageView.image = UIImage(systemName: "exclamationmark.triangle.fill", withConfiguration: configuration)
        iconImageView.tintColor = .systemRed
        iconImageView.contentMode = .scaleAspectFit
        
        // Set fixed size for consistency
        iconImageView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        iconImageView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    }
    
    private func setupMessageLabel() {
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.font = .systemFont(ofSize: 16, weight: .medium)
        messageLabel.textColor = .textPrimary
        messageLabel.text = "Something went wrong"
        
        // Allow label to expand
        messageLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        messageLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    }
    
    private func setupRetryButton() {
        retryButton.setTitle("Retry", for: .normal)
        retryButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        retryButton.backgroundColor = .primaryGreen
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.setTitleColor(.white.withAlphaComponent(0.7), for: .highlighted)
        retryButton.layer.cornerRadius = 8.0
        retryButton.layer.masksToBounds = true
        
        // Add touch feedback similar to OddsButton
        retryButton.addTarget(self, action: #selector(retryButtonTouchDown), for: .touchDown)
        retryButton.addTarget(self, action: #selector(retryButtonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        
        // Set fixed height for button
        retryButton.setContentHuggingPriority(.defaultHigh, for: .vertical)
        retryButton.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    }
    
    private func setupContainerStackView() {
        containerStackView.axis = .vertical
        containerStackView.alignment = .center
        containerStackView.distribution = .fill
        containerStackView.spacing = 24
        
        // Add subviews to stack view
        containerStackView.addArrangedSubview(iconImageView)
        containerStackView.addArrangedSubview(messageLabel)
        containerStackView.addArrangedSubview(retryButton)
    }
    
    private func setupLayout() {
        // Container stack view centered in error view
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
        
        // Retry button sizing
        retryButton.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.width.greaterThanOrEqualTo(120)
        }
    }
    
    // MARK: - Touch Feedback
    
    @objc private func retryButtonTouchDown() {
        retryButton.alpha = 0.8
    }
    
    @objc private func retryButtonTouchUp() {
        UIView.animate(withDuration: 0.1) {
            self.retryButton.alpha = 1.0
        }
    }
    
    @objc private func retryButtonTapped() {
        onRetry?()
    }
    
    // MARK: - Public Methods
    
    /// Shows the error view with optional custom message
    func show(with message: String = "Something went wrong") {
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
    
    func configure(message: String, retryAction: @escaping () -> Void) {
        messageLabel.text = message
        onRetry = retryAction
    }
}
