//
//  WorkoutHistoryView.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/14/23.
//

import SwiftUI

struct WorkoutHistoryView: View {
    
    @Environment(\.workouts) @Binding var workouts
    
    var body: some View {
        List(workouts) { workout in
            HStack {
                Image(systemName: workout.activity.image)
                
                VStack(alignment: .leading) {
                    Text(workout.activity.name)
                        .font(.headline)
                    Text(workout.duration.formatted())
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle("Workouts")
    }
}

struct WorkoutHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WorkoutHistoryView()
        }
        .workouts(.constant([
            Workout(activity: .indoorRide, start: Date(), end: Date().addingTimeInterval(60 * 60 + 30 * 60)),
            Workout(activity: .outdoorRun, start: Date(), end: Date().addingTimeInterval(60 * 45)),
        ]))
    }
}
