//
//  MapLocation.swift
//  trip-planner-pro
//
//  Created by Matt Berman on 7/5/25.
//

import Foundation
import CoreLocation

struct MapLocation: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let unifiedMapURL: String
    let latitude: Double
    let longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(id: UUID = UUID(), name: String, unifiedMapURL: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.unifiedMapURL = unifiedMapURL
        
        // Validate coordinates before storing
        if coordinate.latitude.isFinite && coordinate.longitude.isFinite &&
           coordinate.latitude >= -90 && coordinate.latitude <= 90 &&
           coordinate.longitude >= -180 && coordinate.longitude <= 180 {
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
        } else {
            print("Warning: Invalid coordinates provided for MapLocation '\(name)'. Using default coordinates.")
            self.latitude = 0.0
            self.longitude = 0.0
        }
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MapLocation, rhs: MapLocation) -> Bool {
        lhs.id == rhs.id
    }
} 