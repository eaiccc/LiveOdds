//
//  MockDataProvider.swift
//  MatchOdd
//
//  Description: Provides realistic mock data generation for testing with fictional teams and realistic odds ranges (1.5-5.0)
//
//  Created by Link on 2025/11/13.
//

import Foundation

// MARK: - Mock Data Provider

final class MockDataProvider: @unchecked Sendable {
    
    // MARK: - Properties
    
    /// Fictional team names to avoid real data (NFR-SEC1 compliance)
    /// Expanded to support 100 matches (200 teams needed)
    private let teamNames: [String] = [
        // A-D Teams (40 teams)
        "Arsenal Eagles", "Barcelona Bears", "Chelsea Cats", "Dortmund Dogs",
        "Everton Elephants", "Florence Foxes", "Granada Gazelles", "Hamburg Hawks",
        "Inter Iguanas", "Juventus Jaguars", "Kiev Kangaroos", "Liverpool Lions",
        "Madrid Monkeys", "Naples Newts", "Oxford Owls", "Paris Pandas",
        "Queens Rangers", "Roma Rhinos", "Sevilla Sharks", "Turin Tigers",
        "United Unicorns", "Valencia Vultures", "Wolves Warriors", "Xerez X-Men",
        "York Yaks", "Zagreb Zebras", "Athletic Alpacas", "Bayern Badgers",
        "Celtic Cobras", "Dynamo Dolphins", "Eibar Eagles", "Fiorentina Falcons",
        "Getafe Giraffes", "Hoffenheim Hippos", "Ibiza Iguanas", "Jaen Jaguars",
        "Atletico Antelopes", "Brighton Bees", "Crystal Cranes", "Derby Dragons",
        
        // E-H Teams (40 teams)
        "Everton Eagles", "Fulham Falcons", "Genoa Geese", "Hertha Hawks",
        "Ipswich Iguanas", "Juventus Jays", "Koln Kangaroos", "Leeds Leopards",
        "Marseille Moose", "Norwich Newts", "Osasuna Otters", "Palermo Pandas",
        "Queen Park Quails", "Real Raccoons", "Sampdoria Seals", "Torino Tigers",
        "Udinese Unicorns", "Verona Vultures", "Watford Wolves", "Xerez Zebras",
        "Young Boys Yaks", "Zenit Zebras", "Adelaide Alpacas", "Bristol Bears",
        "Cardiff Cats", "Dublin Dogs", "Edinburgh Eagles", "Frankfurt Foxes",
        "Glasgow Gazelles", "Hull Hawks", "Iceland Iguanas", "Juventus Jays",
        "Kilmarnock Kangaroos", "Leicester Lions", "Manchester Monkeys", "Newcastle Newts",
        "Oldham Owls", "Preston Pandas", "Queens Rangers", "Reading Rhinos",
        
        // I-L Teams (40 teams)
        "Sheffield Sharks", "Tottenham Tigers", "Union Unicorns", "Villa Vultures",
        "West Ham Wolves", "Xmas X-Men", "York Yaks", "Zurich Zebras",
        "Aberdeen Alpacas", "Burnley Bears", "Coventry Cats", "Dundee Dogs",
        "Exeter Eagles", "Forest Foxes", "Grimsby Gazelles", "Hibernian Hawks",
        "Inverness Iguanas", "St Johnstone Jaguars", "Kilmarnock Kangaroos", "Luton Lions",
        "Millwall Monkeys", "Nottingham Newts", "Oldham Owls", "Plymouth Pandas",
        "QPR Quails", "Rochdale Raccoons", "Stockport Seals", "Tranmere Tigers",
        "United Unicorns", "Walsall Vultures", "Wrexham Wolves", "Yeovil Zebras",
        "Alfreton Alpacas", "Boston Bears", "Chester Cats", "Darlington Dogs",
        "Ebbsfleet Eagles", "FC United Foxes", "Gateshead Gazelles", "Harrogate Hawks",
        
        // M-P Teams (40 teams)
        "Isthmian Iguanas", "Jedforest Jaguars", "Kidderminster Kangaroos", "Lancaster Lions",
        "Maidstone Monkeys", "Nuneaton Newts", "Oxford City Owls", "Peterborough Pandas",
        "Quorn Quails", "Rushden Raccoons", "Solihull Seals", "Telford Tigers",
        "United of Manchester Unicorns", "Vauxhall Vultures", "Warrington Wolves", "Xtreme Zebras",
        "Yeading Yaks", "Zulu Zebras", "Aldershot Alpacas", "Barnet Bears",
        "Cambridge Cats", "Dagenham Dogs", "Eastleigh Eagles", "Forest Green Foxes",
        "Gillingham Gazelles", "Hayes Hawks", "Ilkeston Iguanas", "Jarrow Jaguars",
        "Kettering Kangaroos", "Lancaster City Lions", "Marine Monkeys", "Nantwich Newts",
        "Oxford United Owls", "Portsmouth Pandas", "Quakers Quails", "Redditch Raccoons",
        "Southport Seals", "Tamworth Tigers", "Unibond Unicorns", "Vauxhall Motors Vultures",
        
        // Q-T Teams (40 teams)  
        "Wealdstone Wolves", "Xylem Zebras", "York City Yaks", "Zeta Zebras",
        "Accrington Alpacas", "Bradford Bears", "Crewe Cats", "Doncaster Dogs",
        "Exeter City Eagles", "Fleetwood Foxes", "Grimsby Town Gazelles", "Hartlepool Hawks",
        "Ipswich Town Iguanas", "Jacks Jaguars", "Kidderminster Harriers Kangaroos", "Lincoln Lions",
        "Morecambe Monkeys", "Newport Newts", "Oldham Athletic Owls", "Port Vale Pandas",
        "Quinta Quails", "Rotherham Raccoons", "Stevenage Seals", "Torquay Tigers",
        "Utah Unicorns", "Vega Vultures", "Wycombe Wolves", "Xtra Zebras",
        
        // Additional teams to reach 200 total (12 more teams)
        "Alpha Antelopes", "Beta Bears", "Charlie Cats", "Delta Dogs",
        "Echo Eagles", "Foxtrot Foxes", "Golf Gazelles", "Hotel Hawks",
        "India Iguanas", "Juliet Jaguars", "Kilo Kangaroos", "Lima Lions"
    ]
    
    /// Consistent match IDs for generating both matches and odds
    private let matchIDs: [Int] = Array(1...100)
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    /// Generates mock data based on the API endpoint
    /// - Parameter endpoint: The API endpoint requesting data
    /// - Returns: JSON data that can be decoded as appropriate model type
    func generateData(for endpoint: APIEndpoint) -> Data {
        switch endpoint {
        case .matches:
            return generateMatchesData()
        case .odds:
            return generateOddsData()
        }
    }
    
    // MARK: - Private Methods
    
    /// Generates JSON data for matches endpoint
    private func generateMatchesData() -> Data {
        let matches = generateMatches()
        return encodeToData(matches)
    }
    
    /// Generates JSON data for odds endpoint
    private func generateOddsData() -> Data {
        let odds = generateOdds()
        return encodeToData(odds)
    }
    
    /// Generates 100 football matches with mix of LIVE and scheduled
    private func generateMatches() -> [Match] {
        var matches: [Match] = []
        let shuffledTeams = teamNames.shuffled()
        
        for (index, matchID) in matchIDs.enumerated() {
            let teamAIndex = index * 2
            let teamBIndex = teamAIndex + 1
            
            // Ensure we have enough teams for all matches (need 200 teams for 100 matches)
            guard teamBIndex < shuffledTeams.count else { 
                print("Warning: Not enough teams for match \(matchID). Need \(teamBIndex + 1) teams, have \(shuffledTeams.count)")
                break 
            }
            
            let teamA = shuffledTeams[teamAIndex]
            let teamB = shuffledTeams[teamBIndex]
            
            // Create mix of LIVE (~30%) and scheduled (~70%) matches
            let isLive = Double.random(in: 0...1) < 0.3
            
            let match = isLive ? 
                createLiveMatch(id: matchID, teamA: teamA, teamB: teamB) :
                createScheduledMatch(id: matchID, teamA: teamA, teamB: teamB)
            
            matches.append(match)
        }
        
        print("Generated \(matches.count) matches out of requested \(matchIDs.count)")
        return matches
    }
    
    /// Generates odds for all matches with realistic ranges (1.5-5.0)
    private func generateOdds() -> [Odds] {
        return matchIDs.map { matchID in
            let (teamAOdds, drawOdds, teamBOdds) = generateRealisticOdds()
            return Odds(
                matchID: matchID,
                teamAOdds: teamAOdds,
                teamBOdds: teamBOdds,
                drawOdds: drawOdds
            )
        }
    }
    
    /// Generates odds for specific match IDs with 1.20-5.00 range and optional draw odds
    /// - Parameter matchIDs: Array of match IDs to generate odds for
    /// - Returns: Array of Odds matching the provided match IDs
    func generateOdds(for matchIDs: [Int]) -> [Odds] {
        return matchIDs.map { matchID in
            let (teamAOdds, drawOdds, teamBOdds) = generateFlexibleOdds()
            return Odds(
                matchID: matchID,
                teamAOdds: teamAOdds,
                teamBOdds: teamBOdds,
                drawOdds: drawOdds
            )
        }
    }
    
    /// Creates a LIVE match with current score and minute
    private func createLiveMatch(id: Int, teamA: String, teamB: String) -> Match {
        // LIVE matches have past start times
        let startTime = Date().addingTimeInterval(-Double.random(in: 0...5400)) // 0-90 minutes ago
        
        return Match(
            matchID: id,
            teamA: teamA,
            teamB: teamB,
            startTime: startTime,
            isLive: true,
            currentMinute: Int.random(in: 1...95), // 1-95 minutes (including injury time)
            scoreA: Int.random(in: 0...5), // 0-5 goals (typical range)
            scoreB: Int.random(in: 0...5)  // 0-5 goals (typical range)
        )
    }
    
    /// Creates a scheduled match without score information
    private func createScheduledMatch(id: Int, teamA: String, teamB: String) -> Match {
        // Scheduled matches have future start times
        let startTime = Date().addingTimeInterval(Double.random(in: 3600...604800)) // 1 hour to 1 week from now
        
        return Match(
            matchID: id,
            teamA: teamA,
            teamB: teamB,
            startTime: startTime,
            isLive: false,
            currentMinute: nil,
            scoreA: nil,
            scoreB: nil
        )
    }
    
    /// Generates realistic odds within 1.5-5.0 range with balanced probability distribution
    private func generateRealisticOdds() -> (teamA: Double, draw: Double?, teamB: Double) {
        // Generate base odds between 1.5 and 5.0
        let teamAOdds = Double.random(in: 1.5...5.0)
        let teamBOdds = Double.random(in: 1.5...5.0)
        
        // Generate draw odds for football (typically between 2.8 and 4.5)
        let drawOdds = Double.random(in: 2.8...4.5)
        
        // Round to 2 decimal places for realistic display
        return (
            teamA: (teamAOdds * 100).rounded() / 100,
            draw: (drawOdds * 100).rounded() / 100,
            teamB: (teamBOdds * 100).rounded() / 100
        )
    }
    
    /// Generates flexible odds within 1.20-5.00 range with 50% chance of nil draw odds
    private func generateFlexibleOdds() -> (teamA: Double, draw: Double?, teamB: Double) {
        // Generate base odds between 1.20 and 5.00
        let teamAOdds = Double.random(in: 1.20...5.00)
        let teamBOdds = Double.random(in: 1.20...5.00)
        
        // 50% chance of drawOdds being nil (for basketball/tennis)
        let hasDrawOdds = Double.random(in: 0...1) < 0.5
        let drawOdds = hasDrawOdds ? Double.random(in: 2.8...4.5) : nil
        
        // Round to 2 decimal places for realistic display
        return (
            teamA: (teamAOdds * 100).rounded() / 100,
            draw: drawOdds != nil ? (drawOdds! * 100).rounded() / 100 : nil,
            teamB: (teamBOdds * 100).rounded() / 100
        )
    }
    
    /// Encodes any Codable type to JSON Data
    private func encodeToData<T: Codable>(_ value: T) -> Data {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(value)
        } catch {
            // Return empty array as fallback
            return "[]".data(using: .utf8) ?? Data()
        }
    }
}
