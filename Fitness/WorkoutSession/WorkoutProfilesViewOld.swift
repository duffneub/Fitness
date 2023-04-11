//
//  WorkoutProfilesViewOld.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/7/23.
//

import SwiftUI

struct WorkoutProfilesViewOld: View {
    
    @EnvironmentObject private var model: Model
    
    let bluetoothStore: BluetoothStore
    
    var body: some View {
        List(model.profiles) { profile in
            Button {
                model.currentProfile = profile
            } label: {
                HStack {
                    Image(systemName: profile.image)
                    Text(profile.name)
                }
                .foregroundColor(.primary)
            }
        }
        .navigationTitle("Activities")
        .fullScreenCover(item: $model.currentProfile) { profile in
            NavigationStack {
                NewWorkoutView(profile: profile, bluetoothStore: bluetoothStore)
            }
        }
    }
}

//struct ExerciseListView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationStack {
//            WorkoutProfilesViewOld(activities: Activity.allCases)
//        }
//    }
//}
