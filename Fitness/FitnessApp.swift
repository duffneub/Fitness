//
//  FitnessApp.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/7/23.
//

import SwiftUI

@main
struct FitnessApp: App {
    
    let activities: [Activity] = .default
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ActivityListView(activities)
            }
        }
    }

}
