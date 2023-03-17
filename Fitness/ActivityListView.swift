//
//  ActivityListView.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/7/23.
//

import SwiftUI

struct ActivityListView: View {
    
    let activities: [Activity]
    
    var body: some View {
        List(activities) { activity in
            NavigationLink(destination: NewActivityView(activity: activity)) {
                HStack {
                    Image(systemName: activity.image)
                    Text(activity.name)
                }
            }
        }
        .navigationTitle("Activities")
    }
}

struct ExerciseListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ActivityListView(activities: Activity.allCases)
        }
    }
}
