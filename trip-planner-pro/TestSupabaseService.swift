//
//  TestSupabaseService.swift
//  trip-planner-pro
//
//  Created by Matt Berman on 7/5/25.
//

import Foundation
import Supabase
import CoreLocation

@MainActor
class TestSupabaseService: ObservableObject {
    @Published var testResult: String = ""
    @Published var isLoading = false
    
    private let client: SupabaseClient
    
    init() {
        guard let url = URL(string: SupabaseConfig.url) else {
            fatalError("Invalid Supabase URL")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.anonKey
        )
    }
    
    func testConnection() async {
        isLoading = true
        testResult = "Testing connection..."
        
        do {
            // Test basic connection
            testResult += "\n✅ Connected to Supabase"
            
            // Test trips table
            let tripsResponse: [TripResponse] = try await client
                .from("trips")
                .select("""
                    *,
                    map_locations (*),
                    activities (*)
                """)
                .execute()
                .value
            
            testResult += "\n✅ Fetched \(tripsResponse.count) trips from database"
            
            // Print raw response for debugging
            for (index, trip) in tripsResponse.enumerated() {
                testResult += "\n\nTrip \(index + 1):"
                testResult += "\n  ID: \(trip.id)"
                testResult += "\n  Name: \(trip.name)"
                testResult += "\n  Start Date: \(trip.startDate)"
                testResult += "\n  End Date: \(trip.endDate)"
                testResult += "\n  Created At: \(trip.createdAt)"
                testResult += "\n  Updated At: \(trip.updatedAt)"
                testResult += "\n  Map Locations: \(trip.mapLocations?.count ?? 0)"
                testResult += "\n  Activities: \(trip.activities?.count ?? 0)"
                
                // Test date parsing
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                if let startDate = dateFormatter.date(from: trip.startDate) {
                    testResult += "\n  ✅ Start date parsed successfully: \(startDate)"
                } else {
                    testResult += "\n  ❌ Failed to parse start date: '\(trip.startDate)'"
                }
                
                if let endDate = dateFormatter.date(from: trip.endDate) {
                    testResult += "\n  ✅ End date parsed successfully: \(endDate)"
                } else {
                    testResult += "\n  ❌ Failed to parse end date: '\(trip.endDate)'"
                }
                
                // Test trip conversion
                if let convertedTrip = trip.toTrip() {
                    testResult += "\n  ✅ Trip converted successfully: \(convertedTrip.name)"
                } else {
                    testResult += "\n  ❌ Failed to convert trip"
                }
            }
            
            if tripsResponse.isEmpty {
                testResult += "\n\n📝 No trips found in database. This is normal if you haven't created any trips yet."
            }
            
        } catch {
            testResult += "\n❌ Error: \(error.localizedDescription)"
            testResult += "\n\nError details: \(error)"
            
            // Try to get more specific error information
            if let supabaseError = error as? PostgrestError {
                testResult += "\n\nSupabase Error Code: \(supabaseError.code ?? "unknown")"
                testResult += "\nSupabase Error Message: \(supabaseError.message)"
            }
        }
        
        isLoading = false
    }
    
    func testCreateTrip() async {
        isLoading = true
        testResult = "Testing trip creation..."
        
        do {
            let tripId = UUID()
            let now = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            let tripPayload = TripInsertPayload(
                id: tripId.uuidString,
                name: "Test Trip",
                start_date: dateFormatter.string(from: now),
                end_date: dateFormatter.string(from: now.addingTimeInterval(86400 * 7)), // 7 days later
                is_all_day: false,
                created_at: dateFormatter.string(from: now),
                updated_at: dateFormatter.string(from: now)
            )
            
            _ = try await client.from("trips").insert(tripPayload).execute()
            testResult += "\n✅ Test trip created successfully"
            
            // Fetch the trip back to verify
            let response: [TripResponse] = try await client
                .from("trips")
                .select("*")
                .eq("id", value: tripId.uuidString)
                .execute()
                .value
            
            if let createdTrip = response.first {
                testResult += "\n✅ Retrieved created trip: \(createdTrip.name)"
            } else {
                testResult += "\n❌ Could not retrieve created trip"
            }
            
        } catch {
            testResult += "\n❌ Error creating test trip: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

// MARK: - Response Models (using from SupabaseDataService) 