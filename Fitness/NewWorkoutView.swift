//
//  NewWorkoutView.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/9/23.
//

import SwiftUI

struct NewWorkoutView: View {
    
    enum Status {
        case ready
        case inProgress
        case paused
        case complete
    }
    
    @EnvironmentObject var heartRateMonitor: HeartRateMonitor
    
    let activity: Activity
    
    @Environment(\.addWorkout) var addWorkout
    
    @Environment(\.isPresented) var isPresented
    @Environment(\.dismiss) var dismiss
    
    @State private var heartRate: Int?
    
    @State private var start: Date?
    
    @State private var status: Status = .ready
    @State private var duration: Duration = .milliseconds(0)
    
    var body: some View {
        VStack {
            List {
                HStack {
                    Text("Duration")
                        .font(.headline)
                    Spacer()
                    Stopwatch(duration: $duration, isRunning: status == .inProgress) {
                        Text(duration.formatted())
                    }
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
                    start = Date()
                    status = .inProgress
                }
            case .inProgress:
                Button("Pause") {
                    status = .paused
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
                        let workout = Workout(activity: activity, start: start!, end: Date(), activeDuration: duration)
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

struct Stopwatch<Label: View>: View {
    
    @Binding var duration: Duration
    var isRunning: Bool
    let label: () -> Label
    
    @State private var accumulatedTime: Duration
    @State private var timer: Timer?
    
    init(
        duration: Binding<Duration>,
        isRunning: Bool,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self._duration = duration
        self.isRunning = isRunning
        self.label = label
        
        _accumulatedTime = .init(initialValue: duration.wrappedValue)
    }
    
    var body: some View {
        label()
            .onChange(of: isRunning) { isRunning in
                guard isRunning else {
                    pause()
                    return
                }
                
                resume()
            }
    }
    
    private func resume() {
        let now = Date()
        timer = .scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            let seconds = Date().timeIntervalSince(now)
            self.duration = self.accumulatedTime + .seconds(seconds)
        }
    }
    
    private func pause() {
        timer?.invalidate()
        accumulatedTime = duration
    }
    
}

struct NewWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NewWorkoutView(activity: .indoorRide)
        }
        .onAddWorkout { _ in }
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
