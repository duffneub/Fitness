//
//  WorkoutProfilesView.swift
//  Fitness
//
//  Created by Duff Neubauer on 4/11/23.
//

import SwiftUI

struct WorkoutProfilesView: View {
    
    let profiles: [WorkoutProfile]
    
    @Binding var selection: WorkoutProfile
    
    var body: some View {
        List(profiles) { profile in
            Button {
                selection = profile
            } label: {
                Row(profile: profile, isSelected: selection == profile)
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
        .navigationTitle("Workout Profiles")
    }
}

extension WorkoutProfilesView {
    
    struct Row: View {
        
        let profile: WorkoutProfile
        let isSelected: Bool
        
        var body: some View {
            HStack {
                Icon(profile.image)
                Text(profile.name)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                }
            }
            .foregroundColor(isSelected ? .accentColor : .primary)
            .contentShape(Rectangle())
        }
        
    }
    
}

extension WorkoutProfilesView.Row {
    
    struct Icon: View {
        
        let image: String
        
        init(_ image: String) {
            self.image = image
        }
        
        var body: some View {
            Color.clear
                .overlay {
                    Image(systemName: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .frame(width: 30, height: 30)
                .padding(8)
        }
        
    }
    
}

struct WorkoutProfilesView_Previews: PreviewProvider {
    
    static let profiles: [WorkoutProfile] = [
        .init(activity: .outdoorRide),
        .init(activity: .indoorRide),
        .init(activity: .outdoorRun),
    ]
    
    static var previews: some View {
        NavigationStack {
            WorkoutProfilesView(
                profiles: profiles,
                selection: .constant(profiles.first!)
            )
        }
    }
}
