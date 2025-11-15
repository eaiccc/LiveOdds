//
//  FPSCounter.swift
//  MatchOdd
//
//  Description: A lightweight FPS counter for performance monitoring
//
//  Created by Link on 2025/11/13.
//

import UIKit
import QuartzCore
import SnapKit

// MARK: - FPSCounter

/// A lightweight FPS counter that displays real-time frame rate information
/// Inspired by KMCGeigerCounter but implemented in pure Swift
@MainActor
final class FPSCounter {

    // MARK: - Properties

    /// Shared singleton instance
    static let shared = FPSCounter()

    /// Whether the FPS counter is currently enabled
    private(set) var isEnabled: Bool = false

    /// Current FPS value
    private(set) var currentFPS: Int = 0

    /// Display link for frame tracking
    private var displayLink: CADisplayLink?

    /// Last timestamp for FPS calculation
    private var lastTimestamp: CFTimeInterval = 0

    /// Frame count in current second
    private var frameCount: Int = 0

    /// Overlay window for FPS display
    private var overlayWindow: UIWindow?

    /// Label showing FPS information
    private var fpsLabel: UILabel?

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Starts the FPS counter and shows overlay
    func start() {
        guard !isEnabled else { return }
        isEnabled = true

        setupOverlay()
        setupDisplayLink()
    }

    /// Stops the FPS counter and hides overlay
    func stop() {
        guard isEnabled else { return }
        isEnabled = false

        displayLink?.invalidate()
        displayLink = nil
        overlayWindow?.isHidden = true
        overlayWindow = nil
        fpsLabel = nil
    }

    // MARK: - Private Methods

    /// Sets up the overlay window and label
    private func setupOverlay() {
        // Create overlay window
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {

            let window = UIWindow(windowScene: windowScene)
            window.windowLevel = .statusBar + 1
            window.backgroundColor = .clear
            window.isUserInteractionEnabled = false

            // Create FPS label
            let label = UILabel()
            label.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
            label.textAlignment = .center
            label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            label.textColor = .green
            label.layer.cornerRadius = 4
            label.layer.masksToBounds = true

            window.addSubview(label)

            label.snp.makeConstraints { make in
                make.top.equalTo(window.safeAreaLayoutGuide).offset(4)
                make.leading.equalToSuperview().offset(8)
                make.width.equalTo(80)
                make.height.equalTo(24)
            }

            window.isHidden = false

            self.overlayWindow = window
            self.fpsLabel = label
        }
    }

    /// Sets up the display link for frame tracking
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkTick))
        displayLink?.add(to: .main, forMode: .common)
    }

    /// Display link callback for each frame
    @objc private func displayLinkTick(_ link: CADisplayLink) {
        // Initialize lastTimestamp on first call
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }

        frameCount += 1

        // Calculate elapsed time
        let elapsed = link.timestamp - lastTimestamp

        // Update FPS every second
        if elapsed >= 1.0 {
            currentFPS = Int(Double(frameCount) / elapsed)
            frameCount = 0
            lastTimestamp = link.timestamp

            updateDisplay()
        }
    }

    /// Updates the FPS label with current value
    private func updateDisplay() {
        fpsLabel?.text = "\(currentFPS) FPS"

        // Color coding based on FPS
        if currentFPS >= 55 {
            fpsLabel?.textColor = .green      // Good performance
        } else if currentFPS >= 40 {
            fpsLabel?.textColor = .yellow     // Acceptable
        } else {
            fpsLabel?.textColor = .red        // Poor performance
        }
    }
}
