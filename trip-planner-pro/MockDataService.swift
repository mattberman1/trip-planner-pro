//
//  MockDataService.swift
//  trip-planner-pro
//
//  Created by Matt Berman on 7/5/25.
//

import Foundation
import CoreLocation

@MainActor
class MockDataService: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        loadMockData()
    }
    
    private func loadMockData() {
        let mockLocation = MapLocation(
            name: "Sample Location",
            unifiedMapURL: "https://maps.apple.com/?q=Sample",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        )
        
        let mockTrip = Trip(
            name: "Sample Trip",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400),
            cities: [mockLocation]
        )
        
        trips = [mockTrip]
    }
    
    func createTrip(_ trip: Trip) {
        trips.append(trip)
    }
    
    func deleteTrip(_ trip: Trip) {
        trips.removeAll { $0.id == trip.id }
    }
} 