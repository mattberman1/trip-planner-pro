//
//  Trip.swift
//  trip-planner-pro
//
//  Created by Matt Berman on 7/5/25.
//

import Foundation

struct Trip: Identifiable, Codable {
    let id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    var cities: [MapLocation]
    var activities: [Activity]
    let createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), name: String, startDate: Date, endDate: Date, isAllDay: Bool = false, cities: [MapLocation] = [], activities: [Activity] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.cities = cities
        self.activities = activities
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
} 