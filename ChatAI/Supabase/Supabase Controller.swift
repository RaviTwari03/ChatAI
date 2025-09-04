//
//  Supabase Controller.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 04/09/25.
//

import Foundation

// NOTE: These keys are sensitive. Consider moving them into a secure store or .xcconfig for production.
// Provided by user on 2025-09-03.

public enum Secrets {
    // Supabase project ref inferred from token (vzvgwbzvtiwvzlwiepsi)
    public static let supabaseUrl = URL(string: "https://vzvgwbzvtiwvzlwiepsi.supabase.co")!

    // anon/public key
    public static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ6dmd3Ynp2dGl3dnpsd2llcHNpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY3MzcxMTUsImV4cCI6MjA3MjMxMzExNX0.JD_kw4S7051u-02FLnPje49GlbZNzMT5eXpwScAHzf0"

    // service role key (DON'T ship this to clients in production apps)
    public static let supabaseServiceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ6dmd3Ynp2dGl3dnpsd2llcHNpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NjczNzExNSwiZXhwIjoyMDcyMzEzMTE1fQ.Bj3wq4kxHmxnEOn1i7g-T1bl3jP9HuhLukFXBVX5SuE"
}
