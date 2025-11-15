//
//  MockNetworkService.swift
//  MatchOdd
//
//  Description: Mock network service that simulates realistic network behavior with delays for development and testing
//
//  Created by Link on 2025/11/13.
//

import Foundation

// MARK: - Mock Network Service

final class MockNetworkService: @unchecked Sendable, NetworkServicing {
    
    // MARK: - Properties
    
    private let mockDataProvider: MockDataProvider
    
    // MARK: - Initialization
    
    /// Initializes the mock network service with a data provider
    /// - Parameter mockDataProvider: Provider for generating mock data
    init(mockDataProvider: MockDataProvider) {
        self.mockDataProvider = mockDataProvider
    }
    
    // MARK: - NetworkServicing Implementation
    
    /// Performs a simulated network request with realistic delay
    /// - Parameter endpoint: The API endpoint to request data from
    /// - Returns: Decoded response of the specified generic type
    /// - Throws: NetworkError.decodingFailed if JSON decoding fails
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        // Simulate network delay of 0.5 seconds
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds in nanoseconds
        
        // Generate appropriate mock data based on endpoint
        let mockData = mockDataProvider.generateData(for: endpoint)
        
        do {
            // Decode the mock data to the requested type
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: mockData)
        } catch {
            // Wrap decoding errors in NetworkError
            throw NetworkError.decodingFailed(error)
        }
    }
}
