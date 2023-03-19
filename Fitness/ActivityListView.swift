//
//  ActivityListView.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/7/23.
//

import SwiftUI

struct ActivityListView: View {
    
    let activities: [Activity]
    
    @State private var selection: Activity?
    
    var body: some View {
        List(activities) { activity in
            Button {
                selection = activity
            } label: {
                HStack {
                    Image(systemName: activity.image)
                    Text(activity.name)
                }
                .foregroundColor(.primary)
            }
        }
        .navigationTitle("Activities")
        .fullScreenCover(item: $selection) { activity in
            NavigationStack {
                NewWorkoutView(activity: activity)
            }
        }
    }
}

struct ExerciseListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ActivityListView(activities: Activity.allCases)
        }
    }
}
