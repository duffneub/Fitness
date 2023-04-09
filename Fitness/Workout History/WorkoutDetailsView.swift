//
//  WorkoutDetailsView.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/18/23.
//

import SwiftUI

struct WorkoutDetailsView: View {
    
    let workout: Workout
    
    var body: some View {
        List {
            HStack {
                Text("Total Duration")
                    .font(.headline)
                Spacer()
                Text("\(workout.totalDuration.formatted())")
            }
            HStack {
                Text("Active Duration")
                    .font(.headline)
                Spacer()
                Text("\(workout.activeDuration.formatted())")
            }
            HStack {
                Text("Average Heart Rate")
                    .font(.headline)
                Spacer()
                Text("\(workout.averageHeartRate)")
            }
            HStack {
                Text("Average Power")
                    .font(.headline)
                Spacer()
                Text("\(workout.averagePower)")
            }
        }
        .navigationTitle("\(workout.activity.name)")
    }
}

extension [Int] {
    
    var average: Int {
        let sum = reduce(0, +)
        return sum > 0 ? sum / count : 0
    }
    
}

struct WorkoutDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WorkoutDetailsView(workout: .init(
                activity: .outdoorRun,
                start: Date(),
                end: Date().addingTimeInterval(60 * 60),
                samples: [],
                events: []
            ))
        }
    }
}
