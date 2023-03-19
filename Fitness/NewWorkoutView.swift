//
//  NewWorkoutView.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/9/23.
//

import SwiftUI

struct NewWorkoutView: View {
    
    @EnvironmentObject var heartRateMonitor: HeartRateMonitor
    
    let activity: Activity
    
    @Environment(\.addWorkout) var addWorkout
    
    @Environment(\.isPresented) var isPresented
    @Environment(\.dismiss) var dismiss
    
    @State private var totalDuration: Duration = .milliseconds(0)
    @State private var accumulatedTime: Duration = .milliseconds(0)
    @State private var start: Date?
    @State private var timer: Timer?
    @State private var status: Status = .ready
    
    @State private var heartRate: Int?
    
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
                
                HStack {
                    Text("Heart Rate")
                        .font(.headline)
                    Spacer()
                    switch heartRateMonitor.state {
                    case .disconnected:
                        Text("Disconnected")
                    case .connecting:
                        Text("Connecting…")
                    case .connected(let bpm) where bpm == nil:
                        Text("--")
                    case .connected(let bpm):
                        Text("\(bpm!) bpm")
                    case .disconnecting:
                        Text("Disconnecting…")
                    }
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
        .onAppear {
            Task {
                await heartRateMonitor.connect()
            }
        }
    }
}

struct NewWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NewWorkoutView(activity: .indoorRide)
        }
        .workouts([])
        .environmentObject(HeartRateMonitor())
    }
}

class HeartRateMonitor: ObservableObject {
    
    enum State {
        case disconnected
        case connecting
        case connected(Int?)
        case disconnecting
    }
    
    @Published var state: State = .disconnected
    
    func connect() async {
        state = .connecting
        
        try? await Task.sleep(for: .seconds(1))
        
        state = .connected(nil)
        
        try? await Task.sleep(for: .seconds(1))
        
        while true {
            state = .connected((100...180).randomElement()!)
            try? await Task.sleep(for: .seconds([1.0, 1.5, 2.0, 2.5, 3.0].randomElement()!))
        }
    }
    
}
