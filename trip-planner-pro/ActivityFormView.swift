//
//  ActivityFormView.swift
//  trip-planner-pro
//
//  Created by Matt Berman on 7/5/25.
//

import SwiftUI
import MapKit

struct ActivityFormView: View {
    let trip: Trip
    let activity: Activity?
    @ObservedObject var dataService: SupabaseDataService
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var date: Date = Date()
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date().addingTimeInterval(3600) // 1 hour later
    @State private var selectedCity: MapLocation?
    @State private var category: ActivityCategory = .places
    @State private var notes: String = ""
    @State private var isAddedToCalendar: Bool = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    // POI Search State
    @State private var poiQuery: String = ""
    @State private var poiResults: [MKMapItem] = []
    @State private var selectedPOI: MKMapItem?
    @State private var isSearchingPOI = false
    
    private var isEditing: Bool {
        activity != nil
    }
    
    init(trip: Trip, activity: Activity? = nil, dataService: SupabaseDataService) {
        self.trip = trip
        self.activity = activity
        self.dataService = dataService
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Activity Details")) {
                    TextField("Activity Name", text: $name)
                        .disableAutocorrection(true)
                        .autocapitalization(.words)
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                }
                
                Section(header: Text("City")) {
                    Picker("City", selection: $selectedCity) {
                        Text("Select a city").tag(nil as MapLocation?)
                        ForEach(trip.cities) { city in
                            Text(city.name).tag(city as MapLocation?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                if let city = selectedCity {
                    Section(header: Text("Location in \(city.name)")) {
                        TextField("Search for a place (e.g. restaurant, bar, hotel)", text: $poiQuery)
                            .disableAutocorrection(true)
                            .autocapitalization(.words)
                            .onChange(of: poiQuery) { _, newValue in
                                searchPOIs(query: newValue, city: city)
                            }
                        
                        if isSearchingPOI {
                            ProgressView("Searching...")
                        } else if !poiResults.isEmpty {
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 8) {
                                    ForEach(poiResults, id: \.self) { item in
                                        Button(action: {
                                            selectedPOI = item
                                            poiQuery = item.name ?? ""
                                        }) {
                                            VStack(alignment: .leading) {
                                                Text(item.name ?? "Unknown")
                                                    .fontWeight(selectedPOI == item ? .bold : .regular)
                                                if let subtitle = item.placemark.title {
                                                    Text(subtitle)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            .padding(.vertical, 4)
                                        }
                                        .background(selectedPOI == item ? Color.green.opacity(0.1) : Color.clear)
                                        .cornerRadius(6)
                                    }
                                }
                            }
                            .frame(maxHeight: 150)
                        } else if !poiQuery.isEmpty {
                            Text("No results found.")
                                .foregroundColor(.secondary)
                        }
                        if let poi = selectedPOI {
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                Text(poi.name ?? "")
                                Spacer()
                                Button("Clear") {
                                    selectedPOI = nil
                                    poiQuery = ""
                                }
                                .font(.caption)
                            }
                        }
                    }
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $category) {
                        ForEach(ActivityCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.systemImage)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Notes")) {
                    TextField("Add notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Toggle("Add to Calendar", isOn: $isAddedToCalendar)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Activity" : "New Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(isEditing ? "Save" : "Add") {
                            saveActivity()
                        }
                        .disabled(!canSave)
                    }
                }
                
                if isEditing {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Delete") {
                            deleteActivity()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .onAppear {
            setupInitialValues()
        }
    }
    
    private var canSave: Bool {
        !name.isEmpty && startTime <= endTime &&
        selectedCity != nil && selectedPOI != nil &&
        (selectedCity == nil || trip.cities.contains(where: { $0.id == selectedCity!.id })) &&
        ActivityCategory.allCases.contains(category)
    }
    
    private func setupInitialValues() {
        if let activity = activity {
            name = activity.name
            date = activity.date
            startTime = activity.startTime
            endTime = activity.endTime
            selectedCity = activity.location // Assuming location is a MapLocation
            category = activity.category
            notes = activity.notes ?? ""
            isAddedToCalendar = activity.isAddedToCalendar
            // TODO: Set selectedPOI if editing
        } else {
            // Set default values for new activity
            date = trip.startDate
            startTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
            endTime = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: date) ?? date
            selectedCity = trip.cities.first
        }
    }
    
    private func searchPOIs(query: String, city: MapLocation) {
        guard !query.isEmpty else {
            poiResults = []
            return
        }
        isSearchingPOI = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let cityRegion = MKCoordinateRegion(center: city.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        request.region = cityRegion
        // Optionally filter by category
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                isSearchingPOI = false
                if let items = response?.mapItems {
                    poiResults = items
                } else {
                    poiResults = []
                }
            }
        }
    }
    
    private func saveActivity() {
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                guard let selectedCity = selectedCity else {
                    errorMessage = "Please select a city."
                    isSaving = false
                    return
                }
                // Defensive: Ensure city is in trip.cities
                guard trip.cities.contains(where: { $0.id == selectedCity.id }) else {
                    errorMessage = "Selected city is not valid for this trip."
                    isSaving = false
                    return
                }
                // Defensive: Ensure category is valid
                guard ActivityCategory.allCases.contains(category) else {
                    errorMessage = "Selected category is not valid."
                    isSaving = false
                    return
                }
                
                if isEditing {
                    // Update existing activity
                    guard let existingActivity = activity else {
                        errorMessage = "Activity not found"
                        isSaving = false
                        return
                    }
                    
                    let updatedActivity = Activity(
                        id: existingActivity.id,
                        tripId: existingActivity.tripId,
                        name: name,
                        date: date,
                        startTime: startTime,
                        endTime: endTime,
                        city: selectedCity,
                        poiName: selectedPOI?.name,
                        poiAddress: selectedPOI?.placemark.title,
                        poiLatitude: selectedPOI?.placemark.coordinate.latitude,
                        poiLongitude: selectedPOI?.placemark.coordinate.longitude,
                        category: category,
                        notes: notes.isEmpty ? nil : notes,
                        isAddedToCalendar: isAddedToCalendar,
                        createdAt: existingActivity.createdAt,
                        updatedAt: Date()
                    )
                    
                    try await dataService.updateActivity(updatedActivity)
                } else {
                    // Create new activity
                    let newActivity = Activity(
                        id: UUID(),
                        tripId: trip.id,
                        name: name,
                        date: date,
                        startTime: startTime,
                        endTime: endTime,
                        city: selectedCity,
                        poiName: selectedPOI?.name,
                        poiAddress: selectedPOI?.placemark.title,
                        poiLatitude: selectedPOI?.placemark.coordinate.latitude,
                        poiLongitude: selectedPOI?.placemark.coordinate.longitude,
                        category: category,
                        notes: notes.isEmpty ? nil : notes,
                        isAddedToCalendar: isAddedToCalendar
                    )
                    
                    try await dataService.createActivity(newActivity)
                }
                
                // Refresh trip data
                await dataService.fetchTrips()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
    
    private func deleteActivity() {
        guard let activity = activity else { return }
        
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                try await dataService.deleteActivity(activity.id)
                
                // Refresh trip data
                await dataService.fetchTrips()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
} 