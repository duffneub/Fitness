//
//  NewWorkoutView.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/9/23.
//

import SwiftUI

struct NewWorkoutView: View {
    
    let activity: Activity
    
    @Environment(\.addWorkout) var addWorkout
    
    @Environment(\.isPresented) var isPresented
    @Environment(\.dismiss) var dismiss
    
    @State private var totalDuration: Duration = .milliseconds(0)
    @State private var accumulatedTime: Duration = .milliseconds(0)
    @State private var start: Date?
    @State private var timer: Timer?
    @State private var status: Status = .ready
    
    enum Status {
        case ready
        case inProgress
        case paused
        case complete
    }
    
    var body: some View {
        VStack {
            List {
                HStack {
                    Text("Duration")
                        .font(.headline)
                    Spacer()
                    Text(totalDuration.formatted())
                }
            }
            
            Spacer()
            
            switch status {
            case .ready:
                Button("Start") {
                    status = .inProgress
                }
            case .inProgress:
                Button("Pause") {
                    timer?.invalidate()
                    accumulatedTime = totalDuration
                    status = .paused
                }
                .onAppear {
                    let now = Date()
                    start = start ?? now
                    
                    timer = .scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
                        let seconds = Date().timeIntervalSince(now)
                        totalDuration = accumulatedTime + .seconds(seconds)
                    }
                }
            case .paused:
                HStack {
                    Button("Resume") {
                        status = .inProgress
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Button("Stop") {
                        status = .complete
                    }
                }
            case .complete:
                Image(systemName: "checkmark.circle")
                    .onAppear {
                        let workout = Workout(activity: activity, start: start!, end: Date(), activeDuration: accumulatedTime)
                        addWorkout(workout)

                        if isPresented {
                            Task { @MainActor in
                                try? await Task.sleep(for: .seconds(0.3))
                                dismiss()
                            }
                        }
                    }
            }
            
        }
        .navigationTitle(activity.name)
        .buttonStyle(BorderedProminentButtonStyle())
        .controlSize(.large)
    }
}

struct NewActivityView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NewWorkoutView(activity: .indoorRide)
        }
        .workouts([])
    }
}
