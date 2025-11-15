//
//  OddsButton.swift
//  MatchOdd
//
//  Description: Reusable styled button for odds display with type-based styling
//  
//
//  Created by Link on 2025/11/13.
//

import UIKit

// MARK: - OddsType Enum

/// Enumeration representing different types of odds for styling purposes
enum OddsType {
    case win
    case draw
    case lose
}

// MARK: - OddsButton

/// A custom UIButton designed for displaying odds with type-specific styling
final class OddsButton: UIButton {
    
    // MARK: - Properties
    
    private let oddsType: OddsType
    
    // MARK: - Initialization
    
    /// Initializes an OddsButton with the specified type
    /// - Parameter type: The type of odds this button represents
    init(type: OddsType) {
        self.oddsType = type
        super.init(frame: .zero)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupButton() {
        // Set background color based on odds type
        backgroundColor = backgroundColorForType(oddsType)
        
        // Configure appearance
        layer.cornerRadius = 8.0
        layer.masksToBounds = true
        
        // Set title color
        setTitleColor(.white, for: .normal)
        setTitleColor(.white.withAlphaComponent(0.7), for: .highlighted)
        
        // Configure font
        titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        
        // Add touch feedback
        addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
        addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    // MARK: - Helper Methods
    
    /// Returns the appropriate background color for the given odds type
    /// - Parameter type: The odds type
    /// - Returns: The corresponding UIColor
    private func backgroundColorForType(_ type: OddsType) -> UIColor {
        switch type {
        case .win:
            return .oddsWin
        case .draw:
            return .oddsDraw
        case .lose:
            return .oddsLose
        }
    }
    
    // MARK: - Touch Feedback
    
    @objc private func buttonTouchDown() {
        alpha = 0.8
    }
    
    @objc private func buttonTouchUp() {
        alpha = 1.0
    }
    
    // MARK: - Configuration
    
    /// Configures the button with odds value and optional change animation
    /// - Parameters:
    ///   - odds: The odds value to display
    ///   - didChange: Whether odds changed (triggers animation if enabled)
    ///   - animationsEnabled: Whether to show change animations (default: true)
    func configure(odds: Double, didChange: Bool, animationsEnabled: Bool = true) {
        // Set button title using the odds formatting extension
        setTitle(odds.toOddsString(), for: .normal)
        
        // Debug logging
        print("OddsButton configure: odds=\(odds), didChange=\(didChange), animationsEnabled=\(animationsEnabled), type=\(oddsType)")
        
        // Show animation only if odds changed and animations are enabled
        if didChange && animationsEnabled {
            print("Triggering animation for \(oddsType) button")
            showOddsChangeAnimation()
        }
    }
    
    // MARK: - Animation Methods
    
    /// Shows a brief animation to indicate odds have changed
    private func showOddsChangeAnimation() {
        // Debug print to confirm animation is called
        print("Starting odds animation for button: \(oddsType)")
        
        // Ensure animation runs on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Store original values
            let originalBackgroundColor = self.backgroundColor
            
            print("Original color: \(String(describing: originalBackgroundColor))")
            
            // Use a combination of alpha and background color animation
            // This should work even with Auto Layout constraints
            
            // Phase 1: Quick flash with background color change
            UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseOut], animations: {
                self.backgroundColor = self.highlightColorForType(self.oddsType)
                self.alpha = 0.8
            }) { _ in
                // Phase 2: Return to normal
                UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut], animations: {
                    self.backgroundColor = originalBackgroundColor
                    self.alpha = 1.0
                }) { _ in
                    print("Animation completed")
                }
            }
        }
    }
    
    /// Returns the appropriate highlight color for animation
    /// - Parameter type: The odds type
    /// - Returns: The corresponding highlight UIColor
    private func highlightColorForType(_ type: OddsType) -> UIColor {
        switch type {
        case .win:
            return .systemYellow // 更明顯的顏色
        case .draw:
            return .systemOrange // 更明顯的顏色  
        case .lose:
            return .systemPurple // 更明顯的顏色
        }
    }
}
