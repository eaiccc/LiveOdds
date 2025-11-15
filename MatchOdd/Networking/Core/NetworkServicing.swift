//
//  NetworkServicing.swift
//  MatchOdd
//
//  Description: Protocol defining network service interface for async requests with generic response types
//  
//
//  Created by Link on 2025/11/13.
//

import Foundation

// MARK: - Network Servicing Protocol

protocol NetworkServicing: Sendable {
    /// Performs an async network request to the specified endpoint
    /// - Parameter endpoint: The API endpoint to request
    /// - Returns: Decoded response of the specified generic type
    /// - Throws: NetworkError for various failure scenarios
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
}

// MARK: - API Endpoint Enum

enum APIEndpoint: Sendable {
    case matches
    case odds
    
    // MARK: - Properties
    
    var path: String {
        switch self {
        case .matches:
            return "/matches"
        case .odds:
            return "/odds"
        }
    }
    
    /// Base URL for the API endpoints
    private static let baseURL: String = "https://api.example.com"
    
    /// Constructs the full URL for this endpoint
    var url: URL? {
        URL(string: Self.baseURL + path)
    }
    
    /// Creates a URLRequest for this endpoint
    /// - Returns: A configured URLRequest for this endpoint
    /// - Throws: NetworkError.invalidURL if URL construction fails
    func urlRequest() throws -> URLRequest {
        guard let url = url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        return request
    }
    
    /// HTTP method for this endpoint
    private var httpMethod: String {
        switch self {
        case .matches, .odds:
            return "GET"
        }
    }
}

// MARK: - Network Error Types

enum NetworkError: Error, Sendable {
    case invalidURL
    case noData
    case decodingFailed(Error)
    case serverError(Int)
    case networkUnavailable
    case timeout
    case unknown
}

// MARK: - Network Error Descriptions

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無效的 URL"
        case .noData:
            return "無資料回應"
        case .decodingFailed(let error):
            return "資料解析失敗: \(error.localizedDescription)"
        case .serverError(let code):
            return "伺服器錯誤 (\(code))"
        case .networkUnavailable:
            return "網路無法使用"
        case .timeout:
            return "連線逾時"
        case .unknown:
            return "未知錯誤"
        }
    }
}
