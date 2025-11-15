//
//  MatchTableViewCell.swift
//  MatchOdd
//
//  Description: Table view cell for displaying match data with stack view layout for dynamic sizing
//  Adapted from MatchCollectionViewCell with 95% code reuse
//
//  Created by Link on 2025/11/14.
//

import UIKit
import SnapKit

// MARK: - MatchTableViewCell

final class MatchTableViewCell: UITableViewCell {

    // MARK: - Properties

    /// Main vertical stack view containing all cell content
    private let mainStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()

    /// Top horizontal stack view for match ID and live badge
    private let topStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()

    /// Teams horizontal stack view for team names
    private let teamsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .top
        stack.distribution = .fillEqually
        return stack
    }()

    /// Time/Score vertical stack view
    private let timeScoreStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()

    /// Bottom horizontal stack view for odds buttons
    private let oddsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .fill
        stack.distribution = .fillEqually
        return stack
    }()

    /// Live indicator badge for ongoing matches
    let liveBadgeView: LiveBadgeView

    /// Label displaying the unique match identifier
    let matchIDLabel: UILabel

    /// Label displaying the first team name
    let teamALabel: UILabel

    /// Label displaying "vs" text between teams
    private let vsLabel: UILabel

    /// Label displaying the second team name
    let teamBLabel: UILabel

    /// Label displaying match time or status
    let timeLabel: UILabel

    /// Label displaying the current match score
    let scoreLabel: UILabel

    /// Array of three odds buttons for win/draw/lose betting options
    let oddsButtons: [OddsButton]

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        // Initialize UI components
        self.liveBadgeView = LiveBadgeView()
        self.matchIDLabel = UILabel()
        self.teamALabel = UILabel()
        self.vsLabel = UILabel()
        self.teamBLabel = UILabel()
        self.timeLabel = UILabel()
        self.scoreLabel = UILabel()
        self.oddsButtons = [
            OddsButton(type: .win),
            OddsButton(type: .draw),
            OddsButton(type: .lose)
        ]

        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupCell() {
        setupCellAppearance()
        configureLabels()
        buildStackViewHierarchy()
        setupConstraints()
    }

    /// Configure cell appearance
    private func setupCellAppearance() {
        // Configure table view cell specific properties
        selectionStyle = .none
        backgroundColor = .clear
        
        // Apply card styling to contentView (adapted for UITableViewCell)
        // contentView.backgroundColor = .cardBackground
        // contentView.layer.cornerRadius = 12.0
        contentView.layer.masksToBounds = true

        // Shadow effect on cell layer (not content view) - identical to collection cell
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 4.0
        layer.masksToBounds = false
        
        // Additional styling for enhanced card appearance and performance
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        
        // Ensure no unwanted background highlighting
        selectedBackgroundView = UIView()
        
        mainStackView.backgroundColor = .cardBackground
        mainStackView.layer.cornerRadius = 12.0
        mainStackView.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        mainStackView.isLayoutMarginsRelativeArrangement = true
    }

    /// Configure all labels appearance and multi-line support
    private func configureLabels() {
        // Configure match ID label
        matchIDLabel.font = .systemFont(ofSize: 12, weight: .medium)
        matchIDLabel.textColor = .textSecondary
        matchIDLabel.textAlignment = .left
        matchIDLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        matchIDLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Configure team A label with multi-line support
        teamALabel.font = .systemFont(ofSize: 16, weight: .semibold)
        teamALabel.textColor = .textPrimary
        teamALabel.textAlignment = .left
        teamALabel.numberOfLines = 0  // Support multi-line
        teamALabel.lineBreakMode = .byWordWrapping

        // Configure vs label
        vsLabel.font = .systemFont(ofSize: 14, weight: .medium)
        vsLabel.textColor = .textSecondary
        vsLabel.textAlignment = .center
        vsLabel.text = "vs"
        vsLabel.setContentHuggingPriority(.required, for: .horizontal)
        vsLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Configure team B label with multi-line support
        teamBLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        teamBLabel.textColor = .textPrimary
        teamBLabel.textAlignment = .right
        teamBLabel.numberOfLines = 0  // Support multi-line
        teamBLabel.lineBreakMode = .byWordWrapping

        // Configure time label
        timeLabel.font = .systemFont(ofSize: 14, weight: .medium)
        timeLabel.textColor = .textSecondary
        timeLabel.textAlignment = .center

        // Configure score label
        scoreLabel.font = .systemFont(ofSize: 18, weight: .bold)
        scoreLabel.textColor = .primaryGreen
        scoreLabel.textAlignment = .center
    }

    /// Build stack view hierarchy
    private func buildStackViewHierarchy() {
        // Add main stack to content view (CHANGE: contentView instead of direct cell)
        contentView.addSubview(mainStackView)

        // Build top stack: matchID (left), timeLabel (center), and liveBadge (right)
        topStackView.addArrangedSubview(matchIDLabel)
        topStackView.addArrangedSubview(UIView())
        topStackView.addArrangedSubview(timeLabel)
        topStackView.addArrangedSubview(liveBadgeView)

        // Build teams stack: teamA, vs, teamB
        teamsStackView.addArrangedSubview(teamALabel)
        teamsStackView.addArrangedSubview(vsLabel)
        teamsStackView.addArrangedSubview(teamBLabel)

        // Build odds stack: three odds buttons
        for button in oddsButtons {
            oddsStackView.addArrangedSubview(button)
        }

        // Build main stack hierarchy
        mainStackView.addArrangedSubview(topStackView)
        mainStackView.addArrangedSubview(teamsStackView)
        mainStackView.addArrangedSubview(scoreLabel)
        mainStackView.addArrangedSubview(oddsStackView)

        // Initially hide live badge and score label
        liveBadgeView.isHidden = true
        scoreLabel.isHidden = true
    }

    /// Sets up Auto Layout constraints using SnapKit
    private func setupConstraints() {
        // Main stack view with padding (CHANGE: adjusted margins for table view cell)
        mainStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 3, left: 6, bottom: 3, right: 6))
        }

        // Odds buttons fixed height
        for button in oddsButtons {
            button.snp.makeConstraints { make in
                make.height.equalTo(36)
            }
        }

        // Live badge minimum width
        liveBadgeView.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(50)
            make.height.equalTo(24)
        }

        // vs label fixed width
        vsLabel.snp.makeConstraints { make in
            make.width.equalTo(30)
        }
    }

    // MARK: - Cell Lifecycle

    /// Resets the cell state to prepare for reuse
    override func prepareForReuse() {
        super.prepareForReuse()

        // Reset all UI components to default state
        liveBadgeView.isHidden = true

        matchIDLabel.text = nil
        teamALabel.text = nil
        teamBLabel.text = nil
        timeLabel.text = nil
        scoreLabel.text = nil
        scoreLabel.isHidden = true

        // Reset odds buttons state
        for button in oddsButtons {
            button.setTitle(nil, for: .normal)
            button.alpha = 1.0
        }
    }

    // MARK: - Public Methods

    /// Configures the cell with match data
    /// - Parameters:
    ///   - viewData: The match view data to display
    ///   - animationsEnabled: Whether to show odds change animations
    func configure(with viewData: MatchViewData, animationsEnabled: Bool = true) {
        // Configure match information
        matchIDLabel.text = "Match #\(viewData.matchID)"
        teamALabel.text = viewData.teamAName
        teamBLabel.text = viewData.teamBName

        // Configure time display
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        timeLabel.text = formatter.string(from: viewData.startTime)

        // Configure score display
        if viewData.isLive, let scoreA = viewData.scoreA, let scoreB = viewData.scoreB {
            scoreLabel.text = "\(scoreA) - \(scoreB)"
            scoreLabel.isHidden = false
        } else {
            scoreLabel.isHidden = true
        }

        // Show/hide liveBadgeView based on isLive (animation disabled for performance)
        if viewData.isLive {
            liveBadgeView.isHidden = false
            // Animation removed for better FPS
        } else {
            liveBadgeView.isHidden = true
        }

        // Configure odds buttons with animation triggers
        oddsButtons[0].configure(
            odds: viewData.teamAOdds, 
            didChange: viewData.teamAOddsDidChange,
            animationsEnabled: animationsEnabled
        )

        if let drawOdds = viewData.drawOdds {
            oddsButtons[1].configure(
                odds: drawOdds, 
                didChange: viewData.drawOddsDidChange,
                animationsEnabled: animationsEnabled
            )
        } else {
            oddsButtons[1].setTitle("-", for: .normal)
        }

        oddsButtons[2].configure(
            odds: viewData.teamBOdds, 
            didChange: viewData.teamBOddsDidChange,
            animationsEnabled: animationsEnabled
        )

        // Layout updates removed for performance - auto layout handles sizing
    }

    // MARK: - Intrinsic Content Size
    override var intrinsicContentSize: CGSize {
        return mainStackView.systemLayoutSizeFitting(
            CGSize(width: bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }
}
