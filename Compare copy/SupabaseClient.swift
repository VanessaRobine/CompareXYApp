//
//  SupabaseClient.swift
//  Compare
//
//  Created by Vanessa Robine on 3/5/26.
//

import Foundation
import Supabase

final class SupabaseManager {

    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://isoohgmyjvbhxvxbftgi.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlzb29oZ215anZiaHh2eGJmdGdpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MjcyMjE5NiwiZXhwIjoyMDg4Mjk4MTk2fQ.P6CBRjS_xfTJsoRRNyzjr6-M4Uu72GyWwDs9a-ecBac"
        )
           }
       }
