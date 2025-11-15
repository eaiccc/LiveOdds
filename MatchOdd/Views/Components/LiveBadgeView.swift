//
//  LiveBadgeView.swift
//  MatchOdd
//
//  Description: Animated LIVE indicator view for ongoing matches with blinking animation
//  
//
//  Created by Link on 2025/11/13.
//

import UIKit
import QuartzCore
import SnapKit

// MARK: - LiveBadgeView

/// A custom UIView that displays an animated LIVE indicator for ongoing matches
final class LiveBadgeView: UIView {
    
    // MARK: - Properties
    
    private let liveLabel: UILabel
    private let circleLayer: CAShapeLayer
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        self.liveLabel = UILabel()
        self.circleLayer = CAShapeLayer()
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupView() {
        // Configure the label
        setupLabel()

        // Configure the circle layer
        setupCircleLayer()

        // Add label to view
        addSubview(liveLabel)

        // Setup layout
        setupLayout()

        // Animation disabled for better FPS performance
        // startBlinkingAnimation() - removed
    }
    
    private func setupLabel() {
        liveLabel.text = "LIVE"
        liveLabel.textColor = .primaryGreen
        liveLabel.font = .systemFont(ofSize: 8, weight: .bold)
        liveLabel.textAlignment = .center
    }

    private func setupCircleLayer() {
        // Configure circle layer properties
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeColor = UIColor.primaryGreen.cgColor
        circleLayer.lineWidth = 1.0

        // Add circle layer to view's layer
        layer.addSublayer(circleLayer)
    }

    /// Sets up Auto Layout constraints using SnapKit for cleaner syntax
    private func setupLayout() {
        liveLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(8)
            make.trailing.lessThanOrEqualToSuperview().offset(-8)
            make.top.greaterThanOrEqualToSuperview().offset(4)
            make.bottom.lessThanOrEqualToSuperview().offset(-4)
        }
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateCirclePath()
    }
    
    private func updateCirclePath() {
        let inset: CGFloat = 1.0
        let fixedWidth: CGFloat = 30
        let height = bounds.height - inset * 2
        let originX = (bounds.width - fixedWidth) / 2
        let rect = CGRect(x: originX, y: inset, width: fixedWidth, height: height)
        let cornerRadius = min(rect.width, rect.height) / 2
        let roundedPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        circleLayer.path = roundedPath.cgPath
    }
    // MARK: - Animation
    
    /// Starts the blinking animation for the LIVE indicator
    func startBlinkingAnimation() {
        let blinkAnimation = CABasicAnimation(keyPath: "opacity")
        blinkAnimation.fromValue = 0.3
        blinkAnimation.toValue = 1.0
        blinkAnimation.duration = 1.0
        blinkAnimation.autoreverses = true
        blinkAnimation.repeatCount = .infinity
        blinkAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // Apply animation to both the label and circle layer
        liveLabel.layer.add(blinkAnimation, forKey: "blinking")
        circleLayer.add(blinkAnimation, forKey: "blinking")
    }
    
    /// Stops the blinking animation
    func stopBlinkingAnimation() {
        liveLabel.layer.removeAnimation(forKey: "blinking")
        circleLayer.removeAnimation(forKey: "blinking")
        
        // Reset opacity to full
        liveLabel.alpha = 1.0
        circleLayer.opacity = 1.0
    }
    
    // MARK: - Intrinsic Content Size
    
    override var intrinsicContentSize: CGSize {
        let labelSize = liveLabel.intrinsicContentSize
        return CGSize(width: labelSize.width + 16, height: labelSize.height + 8)
    }
}
