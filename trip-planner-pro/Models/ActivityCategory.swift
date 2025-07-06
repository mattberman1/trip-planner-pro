//
//  ActivityCategory.swift
//  trip-planner-pro
//
//  Created by Matt Berman on 7/5/25.
//

import Foundation

enum ActivityCategory: String, CaseIterable, Codable {
    case places = "Places"
    case tours = "Tours"
    case restaurant = "Restaurant"
    case bar = "Bar"
    case travel = "Travel"
    case hotel = "Hotel"
    
    var systemImage: String {
        switch self {
        case .places: return "mappin.circle"
        case .tours: return "figure.walk"
        case .restaurant: return "fork.knife"
        case .bar: return "wineglass"
        case .travel: return "airplane"
        case .hotel: return "bed.double"
        }
    }
} 