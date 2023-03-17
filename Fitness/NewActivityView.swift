//
//  NewActivityView.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/9/23.
//

import SwiftUI



struct NewActivityView: View {
    
    let activity: Activity
    
    @Environment(\.workouts) @Binding var workouts
    
    @State var duration: Duration = .milliseconds(0)
    @State var start: Date?
    @State var timer: Timer?
    @State var status: Status = .ready
    
    enum Status {
        case ready
        case inProgress
        case complete
        
        var title: String {
            switch self {
            case .ready:
                return "Start"
            case .inProgress:
                return "Stop"
            case .complete:
                return "Reset"
                
            }
        }
    }
    
    var body: some View {
        VStack {
            List {
                HStack {
                    Text("Duration")
                        .font(.headline)
                    Spacer()
                    Text(duration.formatted())
                }
            }
            
            Spacer()
            
            Button(start == nil ? "Start" : "Stop") {
                guard start == nil else {
                    timer?.invalidate()
                    
                    let workout = Workout(activity: activity, start: start!, end: Date())
                    workouts.append(workout)

                    return
                }
                
                start = Date()
                timer = .scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
                    let seconds = Date().timeIntervalSince(start!)
                    duration = .seconds(seconds)
                }
            }
            
        }
        .navigationTitle(activity.name)
    }
}

struct NewActivityView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NewActivityView(activity: .indoorRide)
        }
        .workouts(.constant([]))
    }
}
