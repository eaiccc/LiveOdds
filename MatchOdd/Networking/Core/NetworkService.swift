//
//  NetworkService.swift
//  MatchOdd
//
//  Description: Concrete implementation of NetworkServicing using URLSession for real API requests
//  
//
//  Created by Link on 2025/11/13.
//

import Foundation

// MARK: - Network Service Implementation

/// Concrete implementation of NetworkServicing protocol using URLSession
final class NetworkService: NetworkServicing {
    
    // MARK: - Properties
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    // MARK: - Initialization
    
    /// Initializes NetworkService with dependency injection support
    /// - Parameters:
    ///   - session: URLSession instance for network requests (defaults to .shared)
    ///   - decoder: JSONDecoder for response parsing (defaults to configured instance)
    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
        
        // Configure decoder for ISO8601 date formatting if needed
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - NetworkServicing
    
    /// Performs an async network request to the specified endpoint
    /// - Parameter endpoint: The API endpoint to request
    /// - Returns: Decoded response of the specified generic type
    /// - Throws: NetworkError for various failure scenarios
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        do {
            let urlRequest = try endpoint.urlRequest()
            let (data, response) = try await session.data(for: urlRequest)
            
            try validateResponse(response)
            
            guard !data.isEmpty else {
                throw NetworkError.noData
            }
            
            do {
                let decodedResponse = try decoder.decode(T.self, from: data)
                return decodedResponse
            } catch {
                throw NetworkError.decodingFailed(error)
            }
            
        } catch let error as NetworkError {
            throw error
        } catch let urlError as URLError {
            throw mapURLError(urlError)
        } catch {
            throw NetworkError.unknown
        }
    }
    
    // MARK: - Private Methods
    
    /// Validates HTTP response status code and content type
    /// - Parameter response: URLResponse to validate
    /// - Throws: NetworkError.serverError if validation fails
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }
        
        // Validate status code (200-299 range)
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        // Optionally validate content type for JSON responses
        if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
           !contentType.lowercased().contains("application/json") {
            // Log warning but don't throw error to be more permissive
            print("Warning: Expected JSON content type, received: \(contentType)")
        }
    }
    
    /// Maps URLError to appropriate NetworkError case
    /// - Parameter urlError: The URLError to map
    /// - Returns: Corresponding NetworkError
    private func mapURLError(_ urlError: URLError) -> NetworkError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkUnavailable
        case .timedOut:
            return .timeout
        case .badURL, .unsupportedURL:
            return .invalidURL
        default:
            return .unknown
        }
    }
}
