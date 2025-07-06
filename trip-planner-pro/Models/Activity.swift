//
//  Activity.swift
//  trip-planner-pro
//
//  Created by Matt Berman on 7/5/25.
//

import Foundation
import CoreLocation

struct Activity: Identifiable, Codable {
    let id: UUID
    var tripId: UUID
    var name: String
    var date: Date
    var startTime: Date
    var endTime: Date
    var city: MapLocation // The city this activity is in
    var poiName: String? // Name of the specific place (restaurant, bar, etc.)
    var poiAddress: String? // Address of the specific place
    var poiLatitude: Double? // Latitude of the specific place
    var poiLongitude: Double? // Longitude of the specific place
    var category: ActivityCategory
    var notes: String?
    var isAddedToCalendar: Bool
    let createdAt: Date
    var updatedAt: Date
    
    // Computed property for the activity location
    var location: MapLocation {
        if let poiName = poiName, let poiLat = poiLatitude, let poiLon = poiLongitude {
            return MapLocation(
                id: UUID(), // Generate new ID for POI location
                name: poiName,
                unifiedMapURL: "",
                coordinate: CLLocationCoordinate2D(latitude: poiLat, longitude: poiLon)
            )
        } else {
            return city
        }
    }
    
    init(id: UUID, tripId: UUID, name: String, date: Date, startTime: Date, endTime: Date, city: MapLocation, poiName: String? = nil, poiAddress: String? = nil, poiLatitude: Double? = nil, poiLongitude: Double? = nil, category: ActivityCategory, notes: String? = nil, isAddedToCalendar: Bool = false, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.tripId = tripId
        self.name = name
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.city = city
        self.poiName = poiName
        self.poiAddress = poiAddress
        self.poiLatitude = poiLatitude
        self.poiLongitude = poiLongitude
        self.category = category
        self.notes = notes
        self.isAddedToCalendar = isAddedToCalendar
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
} 