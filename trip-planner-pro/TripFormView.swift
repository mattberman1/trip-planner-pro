//
//  TripFormView.swift
//  trip-planner-pro
//
//  Created by Matt Berman on 7/5/25.
//

import SwiftUI
import MapKit

public struct TripFormView: View {
    @ObservedObject var dataService: SupabaseDataService
    @Binding var isPresented: Bool
    
    @State private var name: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(86400)
    @State private var isAllDay: Bool = false
    @State private var cityQuery: String = ""
    @State private var cityResults: [MKLocalSearchCompletion] = []
    @State private var selectedCities: [MapLocation] = []
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showingCitySearch = false
    
    @State private var searchCompleter = MKLocalSearchCompleter()
    @StateObject private var citySearchDelegate = CitySearchDelegate()
    
    public init(dataService: SupabaseDataService, isPresented: Binding<Bool>) {
        self.dataService = dataService
        self._isPresented = isPresented
    }
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Trip Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Trip Details")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            TextField("Trip Name", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                                .disableAutocorrection(true)
                                .autocapitalization(.words)
                            
                            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                .padding(.horizontal)
                            
                            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                                .padding(.horizontal)
                            
                            Toggle("All Day", isOn: $isAllDay)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Cities Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Cities")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            Button(action: {
                                showingCitySearch = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add City")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)
                            
                            if !selectedCities.isEmpty {
                                VStack(spacing: 8) {
                                    ForEach(selectedCities) { city in
                                        HStack {
                                            Text(city.name)
                                                .padding(.leading)
                                            Spacer()
                                            Button(action: {
                                                removeCity(city)
                                            }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .foregroundColor(.red)
                                            }
                                            .padding(.trailing)
                                        }
                                        .padding(.vertical, 8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("New Trip")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { saveTrip() }
                            .disabled(!canSave)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCitySearch) {
            CitySearchView(
                selectedCities: $selectedCities,
                isPresented: $showingCitySearch
            )
        }
        .onAppear {
            setupSearchCompleter()
        }
    }
    
    private var canSave: Bool {
        !name.isEmpty && startDate <= endDate && !selectedCities.isEmpty
    }
    
    private func setupSearchCompleter() {
        searchCompleter.resultTypes = .address
        searchCompleter.delegate = citySearchDelegate
    }
    
    private func removeCity(_ city: MapLocation) {
        selectedCities.removeAll { $0.id == city.id }
    }
    
    private func saveTrip() {
        isSaving = true
        errorMessage = nil
        Task {
            do {
                try await dataService.createTrip(
                    name: name,
                    startDate: startDate,
                    endDate: endDate,
                    isAllDay: isAllDay,
                    cities: selectedCities
                )
                isPresented = false
                await dataService.fetchTrips()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}

// MARK: - City Search View

struct CitySearchView: View {
    @Binding var selectedCities: [MapLocation]
    @Binding var isPresented: Bool
    
    @State private var cityQuery: String = ""
    @State private var cityResults: [MKLocalSearchCompletion] = []
    @State private var searchCompleter = MKLocalSearchCompleter()
    @StateObject private var citySearchDelegate = CitySearchDelegate()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("Search for a city", text: $cityQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .disableAutocorrection(true)
                    .autocapitalization(.words)
                    .onChange(of: cityQuery) { _, newValue in
                        updateCityResults(query: newValue)
                    }
                
                if !cityResults.isEmpty {
                    List(cityResults, id: \.self) { completion in
                        Button(action: {
                            selectCity(completion)
                        }) {
                            Text(completion.title)
                                .foregroundColor(.primary)
                        }
                    }
                } else {
                    Spacer()
                    Text("Search for cities to add to your trip")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .navigationTitle("Add Cities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { isPresented = false }
                }
            }
        }
        .onAppear {
            setupSearchCompleter()
        }
    }
    
    private func setupSearchCompleter() {
        searchCompleter.resultTypes = .address
        searchCompleter.delegate = citySearchDelegate
        citySearchDelegate.onUpdate = { completions in
            cityResults = completions
        }
    }
    
    private func updateCityResults(query: String) {
        if query.isEmpty {
            cityResults = []
        } else {
            searchCompleter.queryFragment = query
        }
    }
    
    private func selectCity(_ completion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error searching for city: \(error)")
                    return
                }
                
                guard let mapItem = response?.mapItems.first else { 
                    print("No map items found for completion")
                    return 
                }
                
                let coordinate = mapItem.placemark.coordinate
                
                // Validate coordinates
                guard coordinate.latitude.isFinite && coordinate.longitude.isFinite,
                      coordinate.latitude >= -90 && coordinate.latitude <= 90,
                      coordinate.longitude >= -180 && coordinate.longitude <= 180 else {
                    print("Invalid coordinates for city: \(completion.title)")
                    return
                }
                
                let city = MapLocation(
                    name: mapItem.placemark.locality ?? completion.title,
                    unifiedMapURL: mapItem.url?.absoluteString ?? "",
                    coordinate: coordinate
                )
                
                if !selectedCities.contains(where: { $0.name == city.name }) {
                    selectedCities.append(city)
                }
                cityQuery = ""
                cityResults = []
            }
        }
    }
}

// MARK: - CitySearchDelegate

class CitySearchDelegate: NSObject, MKLocalSearchCompleterDelegate, ObservableObject {
    var onUpdate: ([MKLocalSearchCompletion]) -> Void = { _ in }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onUpdate(completer.results)
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        onUpdate([])
    }
} 