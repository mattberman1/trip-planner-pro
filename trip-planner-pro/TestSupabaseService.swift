//
//  TestSupabaseService.swift
//  trip-planner-pro
//
//  Created by Matt Berman on 7/5/25.
//

import Foundation
import Supabase

class TestSupabaseService {
    private let client: SupabaseClient
    
    init() {
        guard let url = URL(string: SupabaseConfig.url) else {
            fatalError("Invalid Supabase URL")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.anonKey
        )
    }
    
    func testConnection() -> Bool {
        // This is a simple test to verify the client can be created
        return client.auth.currentUser != nil
    }
} 