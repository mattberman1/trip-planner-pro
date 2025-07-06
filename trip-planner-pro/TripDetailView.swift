//
//  TripDetailView.swift
//  trip-planner-pro
//
//  Created by Matt Berman on 7/5/25.
//

import SwiftUI
import MapKit

struct TripDetailView: View {
    let trip: Trip
    @ObservedObject var dataService: SupabaseDataService
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingActivityForm = false
    @State private var selectedActivity: Activity?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Trip Header
                tripHeader
                
                // Trip Details
                tripDetailsSection
                
                // Cities Section
                citiesSection
                
                // Activities Section
                activitiesSection
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Edit Trip") {
                        showingEditSheet = true
                    }
                    Button("Delete Trip", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            // TODO: Add EditTripView
            Text("Edit Trip - Coming Soon")
                .navigationTitle("Edit Trip")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingEditSheet = false
                        }
                    }
                }
        }
        .sheet(isPresented: $showingActivityForm) {
            ActivityFormView(
                trip: trip,
                activity: selectedActivity,
                dataService: dataService
            )
        }
        .alert("Delete Trip", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTrip()
            }
        } message: {
            Text("Are you sure you want to delete '\(trip.name)'? This action cannot be undone.")
        }
    }
    
    // MARK: - Trip Header
    
    private var tripHeader: some View {
        VStack(spacing: 12) {
            Text(trip.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text(dateRangeText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if trip.isAllDay {
                Text("All Day")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Trip Details Section
    
    private var tripDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trip Details")
                .font(.headline)
            
            VStack(spacing: 12) {
                detailRow(icon: "calendar.badge.clock", title: "Start Date", value: formatDate(trip.startDate))
                detailRow(icon: "calendar.badge.clock", title: "End Date", value: formatDate(trip.endDate))
                detailRow(icon: "clock", title: "Duration", value: durationText)
                detailRow(icon: "mappin.and.ellipse", title: "Cities", value: "\(trip.cities.count) cities")
                detailRow(icon: "list.bullet", title: "Activities", value: "\(trip.activities.count) activities")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Cities Section
    
    private var citiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Cities")
                    .font(.headline)
                Spacer()
                Text("\(trip.cities.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            
            if trip.cities.isEmpty {
                Text("No cities added to this trip yet.")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(trip.cities) { city in
                        cityRow(city)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Activities Section
    
    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Activities")
                    .font(.headline)
                Spacer()
                Text("\(trip.activities.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(8)
            }
            
            if trip.activities.isEmpty {
                VStack(spacing: 12) {
                    Text("No activities planned yet.")
                        .foregroundColor(.secondary)
                        .italic()
                    
                    Button(action: {
                        selectedActivity = nil
                        showingActivityForm = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add First Activity")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
            } else {
                VStack(spacing: 12) {
                    Button(action: {
                        selectedActivity = nil
                        showingActivityForm = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Activity")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    LazyVStack(spacing: 8) {
                        ForEach(trip.activities) { activity in
                            Button(action: {
                                selectedActivity = activity
                                showingActivityForm = true
                            }) {
                                activityRow(activity)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Helper Views
    
    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
    
    private func cityRow(_ city: MapLocation) -> some View {
        HStack {
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(.red)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(city.name)
                    .fontWeight(.medium)
                Text("\(String(format: "%.4f", city.latitude)), \(String(format: "%.4f", city.longitude))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                openInMaps(city)
            }) {
                Image(systemName: "arrow.up.right.square")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func activityRow(_ activity: Activity) -> some View {
        HStack {
            Image(systemName: activityIcon(for: activity.category))
                .foregroundColor(activityColor(for: activity.category))
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.name)
                    .fontWeight(.medium)
                Text(formatActivityTime(activity))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if activity.isAddedToCalendar {
                Image(systemName: "calendar.badge.checkmark")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    
    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: trip.startDate)) - \(formatter.string(from: trip.endDate))"
    }
    
    private var durationText: String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0
        return "\(days + 1) day\(days == 0 ? "" : "s")"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatActivityTime(_ activity: Activity) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: activity.startTime)
    }
    
    private func activityIcon(for category: ActivityCategory) -> String {
        return category.systemImage
    }
    
    private func activityColor(for category: ActivityCategory) -> Color {
        switch category {
        case .places: return .blue
        case .tours: return .green
        case .restaurant: return .orange
        case .bar: return .purple
        case .travel: return .red
        case .hotel: return .pink
        }
    }
    
    private func openInMaps(_ city: MapLocation) {
        let coordinate = city.coordinate
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = city.name
        mapItem.openInMaps(launchOptions: nil)
    }
    
    private func deleteTrip() {
        // TODO: Implement delete functionality
        print("Delete trip: \(trip.id)")
    }
} 