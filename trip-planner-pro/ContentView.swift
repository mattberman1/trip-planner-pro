//
//  ContentView.swift
//  trip-planner-pro
//
//  Created by Matt Berman on 7/5/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataService = SupabaseDataService()
    @State private var showingTripForm = false
    
    var body: some View {
        NavigationView {
            Group {
                if dataService.isLoading {
                    ProgressView("Loading trips...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = dataService.errorMessage {
                    VStack {
                        Text(error)
                            .foregroundColor(.red)
                        Button("Retry") {
                            Task { await dataService.fetchTrips() }
                        }
                        .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if dataService.trips.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "airplane.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        Text("No trips yet")
                            .font(.title2)
                            .fontWeight(.medium)
                        Text("Create your first trip to get started")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Create Trip") {
                            showingTripForm = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(dataService.trips) { trip in
                        NavigationLink(destination: TripDetailView(tripId: trip.id, dataService: dataService)) {
                            tripRow(trip)
                        }
                    }
                }
            }
            .navigationTitle("My Trips")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingTripForm = true }) {
                        Label("Create New Trip", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingTripForm) {
                TripFormView(dataService: dataService, isPresented: $showingTripForm)
            }
        }
        .task {
            await dataService.fetchTrips()
        }
    }
    
    private func tripRow(_ trip: Trip) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(dateRangeText(for: trip))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !trip.cities.isEmpty {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text("\(trip.cities.count) cit\(trip.cities.count == 1 ? "y" : "ies")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func dateRangeText(for trip: Trip) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: trip.startDate)) - \(formatter.string(from: trip.endDate))"
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

#Preview {
    ContentView()
}
