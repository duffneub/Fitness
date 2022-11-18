//
//  WorkoutListView.swift
//  Fitness
//
//  Created by Duff Neubauer on 11/18/22.
//

import HealthKit
import SwiftUI

struct Workout {
    
    let name: String
    let isDisabled: Bool
    
}

extension Workout: Identifiable {
    
    var id: String { name }
    
}

struct WorkoutListView: View {
    
    let workouts: [Workout] = [
        Workout(name: "Indoor Cycling", isDisabled: false),
        Workout(name: "Running", isDisabled: true),
        Workout(name: "Cycling", isDisabled: true),
    ]
    
    var body: some View {
        List(workouts) { workout in
            NavigationLink {
                PairDevicesView()
            } label: {
                Text(workout.name)
            }
            .disabled(workout.isDisabled)
        }
        .navigationTitle("Workouts")
    }
}

struct WorkoutListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WorkoutListView()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
