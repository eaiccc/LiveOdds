//
//  SceneDelegate.swift
//  MatchOdd
//
//  Created by Link on 2025/11/12.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Create dependency chain
        let mockDataProvider = MockDataProvider()
        let mockNetworkService = MockNetworkService(mockDataProvider: mockDataProvider)
        let matchRepository = MatchRepository(networkService: mockNetworkService)
        
        // Create MockOddsStreamManager with match IDs from repository
        // Note: Using hardcoded match IDs (1...30) as per current MockOddsStreamManager implementation
        // In a real-world scenario, these would be obtained from the repository after initial data load
        let mockOddsStreamManager = MockOddsStreamManager()
        
        // Create MatchListViewModel with dependencies
        let matchListViewModel = MatchListViewModel(
            repository: matchRepository,
            oddsStreamManager: mockOddsStreamManager
        )
        
        // Create MatchListViewController and wrap in UINavigationController
        let matchListViewController = MatchListViewController(viewModel: matchListViewModel)
        let navigationController = UINavigationController(rootViewController: matchListViewController)
        
        // Configure window
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        // Start odds streaming
        mockOddsStreamManager.startStreaming()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.

        // Start FPS counter for performance monitoring (Debug only)
        #if DEBUG
        Task { @MainActor in
            FPSCounter.shared.start()
        }
        #endif
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).

        // Stop FPS counter when app becomes inactive
        #if DEBUG
        Task { @MainActor in
            FPSCounter.shared.stop()
        }
        #endif
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

