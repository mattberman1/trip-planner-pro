//
//  TestView.swift
//  trip-planner-pro
//
//  Created by Matt Berman on 7/5/25.
//

import SwiftUI

struct TestView: View {
    @StateObject private var testService = TestSupabaseService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Supabase Connection Test")
                    .font(.title)
                    .fontWeight(.bold)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(testService.testResult)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                HStack(spacing: 20) {
                    Button("Test Connection") {
                        Task {
                            await testService.testConnection()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(testService.isLoading)
                    
                    Button("Create Test Trip") {
                        Task {
                            await testService.testCreateTrip()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(testService.isLoading)
                }
                
                if testService.isLoading {
                    ProgressView("Testing...")
                        .padding()
                }
            }
            .padding()
            .navigationTitle("Database Test")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await testService.testConnection()
        }
    }
}

#Preview {
    TestView()
} 