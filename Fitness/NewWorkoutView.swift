//
//  NewWorkoutView.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/9/23.
//

import SwiftUI

class WorkoutBuilder: ObservableObject {
    
    enum Status {
        case ready
        case inProgress
        case paused
        case complete
    }
    
    private(set) var totalDuration: Duration = .milliseconds(0)
    private(set) var status: Status = .ready
    
    private(set) var accumulatedTime: Duration = .milliseconds(0)
    private(set) var startDate: Date?
    private var timer: Timer?
    
    func start() {
        status = .inProgress
        startDate = Date()
        startTimer(startDate!)
    }
    
    func pause() {
        timer?.invalidate()
        accumulatedTime = totalDuration
        status = .paused
    }
    
    func resume() {
        status = .inProgress
        startTimer(.init())
    }
    
    func stop() {
        status = .complete
    }
    
    private func startTimer(_ date: Date) {
        timer = .scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            let seconds = Date().timeIntervalSince(date)
            self.totalDuration = self.accumulatedTime + .seconds(seconds)
        }
    }
    
}

struct NewWorkoutView: View {
    
    @EnvironmentObject var heartRateMonitor: HeartRateMonitor
    @EnvironmentObject var workoutBuilder: WorkoutBuilder
    
    let activity: Activity
    
    @Environment(\.addWorkout) var addWorkout
    
    @Environment(\.isPresented) var isPresented
    @Environment(\.dismiss) var dismiss
    
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
                    Text(workoutBuilder.totalDuration.formatted())
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
            
            switch workoutBuilder.status {
            case .ready:
                Button("Start") {
                    workoutBuilder.start()
                }
            case .inProgress:
                Button("Pause") {
                    workoutBuilder.pause()
                }
            case .paused:
                HStack {
                    Button("Resume") {
                        workoutBuilder.resume()
                    }
                    .buttonStyle(BorderedButtonStyle())
                    
                    Button("Stop") {
                        workoutBuilder.stop()
                    }
                }
            case .complete:
                Image(systemName: "checkmark.circle")
                    .onAppear {
                        let workout = Workout(activity: activity, start: workoutBuilder.startDate!, end: Date(), activeDuration: workoutBuilder.accumulatedTime)
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
        .onAddWorkout { _ in }
        .environmentObject(HeartRateMonitor())
        .environmentObject(WorkoutBuilder())
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
