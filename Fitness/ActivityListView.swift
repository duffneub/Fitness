//
//  ActivityListView.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/7/23.
//

import SwiftUI

struct Activity {
    
    let name: String
    let image: String

}

extension [Activity] {
    
    static let `default`: Self = [
        Activity(name: "Ride", image: "figure.outdoor.cycle"),
        Activity(name: "Indoor Ride", image: "figure.indoor.cycle"),
        Activity(name: "Run", image: "figure.run"),
        Activity(name: "Indoor Run", image: "figure.run"),
    ]
    
}

extension Activity: Identifiable {
    
    var id: String { name }
    
}

struct ActivityListView: View {
    
    let activities: [Activity]
    
    init(_ activities: [Activity]) {
        self.activities = activities
    }
    
    var body: some View {
        List(activities) { exercise in
            HStack {
                Image(systemName: exercise.image)
                Text(exercise.name)
            }
        }
        .navigationTitle("Activities")
    }
}

struct ExerciseListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ActivityListView(.default)
        }
    }
}
