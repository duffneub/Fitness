//
//  WorkoutHistoryView.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/14/23.
//

import SwiftUI

struct WorkoutHistoryView: View {
    
    @Environment(\.workouts) var workouts
    
    var body: some View {
        List(workouts) { workout in
            NavigationLink(value: workout) {
                HStack {
                    Image(systemName: workout.activity.image)
                    
                    VStack(alignment: .leading) {
                        Text(workout.activity.name)
                            .font(.headline)
                        Text(workout.totalDuration.formatted())
                            .font(.subheadline)
                    }
                }
            }

        }
        .navigationTitle("Workouts")
        .navigationDestination(for: Workout.self) { workout in
            WorkoutDetailsView(workout: workout)
        }
    }
}

struct WorkoutHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WorkoutHistoryView()
        }
        .workouts([
            Workout(activity: .indoorRide, start: Date(), end: Date().addingTimeInterval(60 * 60 + 30 * 60), activeDuration: .seconds(0)),
            Workout(activity: .outdoorRun, start: Date(), end: Date().addingTimeInterval(60 * 45), activeDuration: .seconds(0)),
        ])
    }
}
