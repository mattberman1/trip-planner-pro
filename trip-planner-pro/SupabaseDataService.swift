//
//  SupabaseDataService.swift
//  trip-planner-pro
//
//  Created by Matt Berman on 7/5/25.
//

import Foundation
import Supabase
import CoreLocation

@MainActor
public class SupabaseDataService: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
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
    
    func fetchTrips() async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("Fetching trips from Supabase...")
            let response: [TripResponse] = try await client
                .from("trips")
                .select("""
                    *,
                    map_locations (*),
                    activities (*)
                """)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            print("Fetched \(response.count) trips from Supabase")
            
            // Debug: Print raw response data
            for (index, tripResponse) in response.enumerated() {
                print("Trip \(index):")
                print("  ID: \(tripResponse.id)")
                print("  Name: \(tripResponse.name)")
                print("  Start Date: \(tripResponse.startDate)")
                print("  End Date: \(tripResponse.endDate)")
                print("  Created At: \(tripResponse.createdAt)")
                print("  Updated At: \(tripResponse.updatedAt)")
                print("  Map Locations: \(tripResponse.mapLocations?.count ?? 0)")
                print("  Activities: \(tripResponse.activities?.count ?? 0)")
            }
            
            trips = response.compactMap { tripResponse in
                guard let trip = tripResponse.toTrip() else {
                    print("Failed to convert trip response: \(tripResponse)")
                    print("Trip ID: \(tripResponse.id)")
                    print("Start Date: \(tripResponse.startDate)")
                    print("End Date: \(tripResponse.endDate)")
                    print("Created At: \(tripResponse.createdAt)")
                    print("Updated At: \(tripResponse.updatedAt)")
                    if let locations = tripResponse.mapLocations {
                        print("Map Locations count: \(locations.count)")
                        for (index, location) in locations.enumerated() {
                            print("Location \(index): \(location.name) - lat: \(location.latitude), lon: \(location.longitude)")
                        }
                    }
                    return nil
                }
                print("Successfully converted trip: \(trip.name)")
                return trip
            }
            
            print("Successfully converted \(trips.count) trips")
            
        } catch {
            errorMessage = "Failed to fetch trips: \(error.localizedDescription)"
            print("Error fetching trips: \(error)")
            print("Error details: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Create Trip
    func createTrip(name: String, startDate: Date, endDate: Date, isAllDay: Bool, cities: [MapLocation]) async throws {
        let tripId = UUID()
        let now = Date()
        let tripPayload = TripInsertPayload(
            id: tripId.uuidString,
            name: name,
            start_date: isoDate(startDate),
            end_date: isoDate(endDate),
            is_all_day: isAllDay,
            created_at: isoDate(now),
            updated_at: isoDate(now)
        )
        _ = try await client.from("trips").insert(tripPayload).execute()
        for city in cities {
            let cityPayload = MapLocationInsertPayload(
                id: city.id.uuidString,
                trip_id: tripId.uuidString,
                name: city.name,
                unified_map_url: city.unifiedMapURL,
                latitude: city.latitude,
                longitude: city.longitude
            )
            _ = try await client.from("map_locations").insert(cityPayload).execute()
        }
    }
    
    private func isoDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // MARK: - Activity Methods
    
    func createActivity(_ activity: Activity) async throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        
        let activityData = ActivityCreateRequest(
            id: activity.id.uuidString,
            tripId: activity.tripId.uuidString,
            name: activity.name,
            date: dateFormatter.string(from: activity.date),
            startTime: timeFormatter.string(from: activity.startTime),
            endTime: timeFormatter.string(from: activity.endTime),
            cityId: activity.city.id.uuidString,
            poiName: activity.poiName,
            poiAddress: activity.poiAddress,
            poiLatitude: activity.poiLatitude,
            poiLongitude: activity.poiLongitude,
            category: activity.category.rawValue,
            notes: activity.notes,
            isAddedToCalendar: activity.isAddedToCalendar
        )
        
        try await client
            .from("activities")
            .insert(activityData)
            .execute()
        
        print("Successfully created activity: \(activity.name)")
    }
    
    func updateActivity(_ activity: Activity) async throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        
        let activityData = ActivityUpdateRequest(
            name: activity.name,
            date: dateFormatter.string(from: activity.date),
            startTime: timeFormatter.string(from: activity.startTime),
            endTime: timeFormatter.string(from: activity.endTime),
            cityId: activity.city.id.uuidString,
            poiName: activity.poiName,
            poiAddress: activity.poiAddress,
            poiLatitude: activity.poiLatitude,
            poiLongitude: activity.poiLongitude,
            category: activity.category.rawValue,
            notes: activity.notes,
            isAddedToCalendar: activity.isAddedToCalendar,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        try await client
            .from("activities")
            .update(activityData)
            .eq("id", value: activity.id.uuidString)
            .execute()
        
        print("Successfully updated activity: \(activity.name)")
    }
    
    func deleteActivity(_ activityId: UUID) async throws {
        try await client
            .from("activities")
            .delete()
            .eq("id", value: activityId.uuidString)
            .execute()
        
        print("Successfully deleted activity: \(activityId)")
    }
}

// MARK: - Response Models

struct TripResponse: Codable {
    let id: String
    let name: String
    let startDate: String
    let endDate: String
    let isAllDay: Bool
    let createdAt: String
    let updatedAt: String
    let mapLocations: [MapLocationResponse]?
    let activities: [ActivityResponse]?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case startDate = "start_date"
        case endDate = "end_date"
        case isAllDay = "is_all_day"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case mapLocations = "map_locations"
        case activities = "activities"
    }
    
    func toTrip() -> Trip? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Debug date parsing
        print("Parsing start date: '\(startDate)'")
        print("Parsing end date: '\(endDate)'")
        
        guard let startDate = dateFormatter.date(from: startDate) else {
            print("Failed to parse start date: '\(startDate)'")
            return nil
        }
        
        guard let endDate = dateFormatter.date(from: endDate) else {
            print("Failed to parse end date: '\(endDate)'")
            return nil
        }
        
        // Try ISO8601 for created/updated dates
        let isoFormatter = ISO8601DateFormatter()
        let createdAt = isoFormatter.date(from: self.createdAt) ?? Date()
        let updatedAt = isoFormatter.date(from: self.updatedAt) ?? Date()
        
        let cities = mapLocations?.compactMap { $0.toMapLocation() } ?? []
        print("Found \(cities.count) cities for trip \(name)")
        print("Trip city IDs: \(cities.map { $0.id.uuidString })")
        
        let activities: [Activity] = self.activities?.compactMap { activityResponse in
            print("\n--- Activity Debug ---")
            print("Activity name: \(activityResponse.name)")
            print("Activity cityId: \(activityResponse.cityId)")
            print("Activity category: \(activityResponse.category)")
            print("All enum categories: \(ActivityCategory.allCases.map { $0.rawValue })")
            guard let activity = activityResponse.toActivity(tripId: UUID(uuidString: id) ?? UUID(), cities: cities) else {
                print("Failed to convert activity: \(activityResponse.name)")
                print("  Date: \(activityResponse.date)")
                print("  Start Time: \(activityResponse.startTime)")
                print("  End Time: \(activityResponse.endTime)")
                print("  City ID: \(activityResponse.cityId)")
                return nil
            }
            print("Successfully converted activity: \(activity.name)")
            return activity
        } ?? []
        
        print("Trip \(name) has \(activities.count) activities")
        
        return Trip(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            cities: cities,
            activities: activities,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct MapLocationResponse: Codable {
    let id: String
    let name: String
    let unifiedMapURL: String
    let latitude: Double
    let longitude: Double
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case unifiedMapURL = "unified_map_url"
        case latitude, longitude
    }
    
    func toMapLocation() -> MapLocation? {
        // Validate coordinates to prevent NaN values
        guard latitude.isFinite && longitude.isFinite,
              latitude >= -90 && latitude <= 90,
              longitude >= -180 && longitude <= 180 else {
            print("Invalid coordinates: lat=\(latitude), lon=\(longitude)")
            return nil
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        return MapLocation(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            unifiedMapURL: unifiedMapURL,
            coordinate: coordinate
        )
    }
}

// MARK: - Activity Response Models

struct ActivityResponse: Codable {
    let id: String
    let tripId: String
    let name: String
    let date: String
    let startTime: String
    let endTime: String
    let cityId: String
    let poiName: String?
    let poiAddress: String?
    let poiLatitude: Double?
    let poiLongitude: Double?
    let category: String
    let notes: String?
    let isAddedToCalendar: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case tripId = "trip_id"
        case name
        case date
        case startTime = "start_time"
        case endTime = "end_time"
        case cityId = "city_id"
        case poiName = "poi_name"
        case poiAddress = "poi_address"
        case poiLatitude = "poi_latitude"
        case poiLongitude = "poi_longitude"
        case category
        case notes
        case isAddedToCalendar = "is_added_to_calendar"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    func toActivity(tripId: UUID, cities: [MapLocation]) -> Activity? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        print("[toActivity] cities passed in: \(cities.map { $0.id.uuidString })")
        print("[toActivity] cityId to match: \(cityId)")
        print("[toActivity] category to match: \(category)")
        print("[toActivity] all enum categories: \(ActivityCategory.allCases.map { $0.rawValue })")
        
        guard let date = dateFormatter.date(from: self.date),
              let city = cities.first(where: { $0.id.uuidString.lowercased() == cityId.lowercased() }),
              let activityCategory = ActivityCategory(rawValue: category) else {
            print("Failed to convert activity: \(name)")
            print("  - Date parsing failed: '\(self.date)'")
            print("  - City not found for ID: \(cityId)")
            print("  - Category not found: '\(category)'")
            return nil
        }
        
        // Parse time strings and combine with the activity date
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        
        // Create start time by combining date and time
        let startTimeString = "\(self.date) \(self.startTime)"
        let startTimeFormatter = DateFormatter()
        startTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // Create end time by combining date and time
        let endTimeString = "\(self.date) \(self.endTime)"
        let endTimeFormatter = DateFormatter()
        endTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        guard let startTime = startTimeFormatter.date(from: startTimeString),
              let endTime = endTimeFormatter.date(from: endTimeString) else {
            print("Failed to parse times for activity: \(name)")
            print("  - Start time string: '\(startTimeString)'")
            print("  - End time string: '\(endTimeString)'")
            return nil
        }
        
        // Try ISO8601 for created/updated dates
        let isoFormatter = ISO8601DateFormatter()
        let createdAt = isoFormatter.date(from: self.createdAt) ?? Date()
        let updatedAt = isoFormatter.date(from: self.updatedAt) ?? Date()
        
        print("Successfully converted activity: \(name)")
        
        return Activity(
            id: UUID(uuidString: id) ?? UUID(),
            tripId: tripId,
            name: name,
            date: date,
            startTime: startTime,
            endTime: endTime,
            city: city,
            poiName: poiName,
            poiAddress: poiAddress,
            poiLatitude: poiLatitude,
            poiLongitude: poiLongitude,
            category: activityCategory,
            notes: notes,
            isAddedToCalendar: isAddedToCalendar,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct TripInsertPayload: Encodable {
    let id: String
    let name: String
    let start_date: String
    let end_date: String
    let is_all_day: Bool
    let created_at: String
    let updated_at: String
}

struct MapLocationInsertPayload: Encodable {
    let id: String
    let trip_id: String
    let name: String
    let unified_map_url: String
    let latitude: Double
    let longitude: Double
}

// MARK: - Activity Request Models

struct ActivityCreateRequest: Codable {
    let id: String
    let tripId: String
    let name: String
    let date: String
    let startTime: String
    let endTime: String
    let cityId: String
    let poiName: String?
    let poiAddress: String?
    let poiLatitude: Double?
    let poiLongitude: Double?
    let category: String
    let notes: String?
    let isAddedToCalendar: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, date, notes, category
        case tripId = "trip_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case cityId = "city_id"
        case poiName = "poi_name"
        case poiAddress = "poi_address"
        case poiLatitude = "poi_latitude"
        case poiLongitude = "poi_longitude"
        case isAddedToCalendar = "is_added_to_calendar"
    }
}

struct ActivityUpdateRequest: Codable {
    let name: String
    let date: String
    let startTime: String
    let endTime: String
    let cityId: String
    let poiName: String?
    let poiAddress: String?
    let poiLatitude: Double?
    let poiLongitude: Double?
    let category: String
    let notes: String?
    let isAddedToCalendar: Bool
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case name, date, notes, category, updatedAt
        case startTime = "start_time"
        case endTime = "end_time"
        case cityId = "city_id"
        case poiName = "poi_name"
        case poiAddress = "poi_address"
        case poiLatitude = "poi_latitude"
        case poiLongitude = "poi_longitude"
        case isAddedToCalendar = "is_added_to_calendar"
    }
} 