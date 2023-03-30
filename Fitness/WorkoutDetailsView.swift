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
                Text("\(workout.heartRateSamples.map(\.value).average)")
            }
            HStack {
                Text("Average Power")
                    .font(.headline)
                Spacer()
                Text("\(workout.powerSamples.map(\.value).average)")
            }
        }
        .navigationTitle("\(workout.activity.name)")
    }
}

extension [Int] {
    
    var average: Int {
        reduce(0, +) / count
    }
    
}

struct WorkoutDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WorkoutDetailsView(workout: .init(
                activity: .outdoorRun,
                start: Date(),
                end: Date().addingTimeInterval(60 * 60),
                activeDuration: .seconds(60 * 45),
                heartRateSamples: [],
                powerSamples: []
            ))
        }
    }
}
