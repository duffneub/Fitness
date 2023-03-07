//
//  ExerciseListView.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/7/23.
//

import SwiftUI

struct Exercise {
    
    let name: String
    let image: String

}

extension Exercise: Identifiable {
    
    var id: String { name }
    
}

struct ExerciseListView: View {
    
    let exercises: [Exercise]
    
    var body: some View {
        List(exercises) { exercise in
            HStack {
                Image(systemName: exercise.image)
                Text(exercise.name)
            }
        }
    }
}

struct ExerciseListView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseListView(exercises: [
            Exercise(name: "Ride", image: "figure.outdoor.cycle"),
            Exercise(name: "Indoor Ride", image: "figure.indoor.cycle"),
            Exercise(name: "Run", image: "figure.run"),
            Exercise(name: "Indoor Run", image: "figure.run"),
        ])
    }
}
