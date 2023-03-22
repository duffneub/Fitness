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
                
                NavigationLink(value: 1) {
                    HStack {
                        Text("Heart Rate")
                            .font(.headline)
                        Spacer()
                        
                        Text("Search")
                    }
                }
            }
            
            Spacer()
            
            StartStopControls(status: $status)
        }
        .navigationDestination(for: Int.self) { _ in
            FindDevicesView()
        }
        .navigationTitle(activity.name)
        .onChange(of: status) { newStatus in
            switch status {
            case .inProgress:
                startWorkout()
            case .complete:
                stopWorkout()
            case .ready, .paused:
                break
            }
        }
    }
    
    private func startWorkout() {
        start = start ?? Date()
    }
    
    private func stopWorkout() {
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

struct FindDevicesView: View {
    
//    @Binding var selectedDevice: Device
    @State private var sensorMap: [UUID: Sensor] = [:]
    
    var sensors: [Sensor] {
        Array(sensorMap.values)
    }
    
    @Environment(\.sensorStore) var sensorStore
    
    var body: some View {
        List(sensors) { sensor in
            Text(sensor.name)
        }
        .navigationTitle("Devices…")
        .task {
            for await sensor in sensorStore.sensors(withServices: [.heartRate]) {
                sensorMap[sensor.id] = sensor
            }
        }
        .menuStyle(.automatic)
    }
    
}

struct Sensor: Identifiable {
    
    enum Service {
        case heartRate
    }
    
    let id: UUID
    let name: String
    let services: [Service]
    
}

extension SensorStore where Self == PreviewSensorStore {
    
    static var preview: Self { Self() }
    
}

struct StartStopControls: View {
    
    @Binding var status: NewWorkoutView.Status
    
    var body: some View {
        Group {
            switch status {
            case .ready:
                Button("Start") {
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
                EmptyView()
            }
        }
        .buttonStyle(BorderedProminentButtonStyle())
        .controlSize(.large)
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

struct HeartRateMonitor<Label: View>: View {
    
    enum State {
        case disconnected
        case connecting
        case connected(Int?)
        case disconnecting
    }
    
    @SwiftUI.State private var state: State = .disconnected
    
    let label: (State) -> Label
    
    init(@ViewBuilder label: @escaping (State) -> Label) {
        self.label = label
    }
    
    var body: some View {
        label(state)
//            .task {
//                await connect()
//            }
    }
    
    private func connect() async {
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

// MARK: - Preview

struct NewWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack(path: .constant(.init([1]))) {
            NewWorkoutView(activity: .indoorRide)
        }
        .onAddWorkout { _ in }
        .sensorStore(.preview)
    }
}

struct PreviewSensorStore: SensorStore {
    
    let sensors: [Sensor] = [
        Sensor(id: UUID(), name: "Wahoo Tickr", services: [.heartRate]),
        Sensor(id: UUID(), name: "Polar H9", services: [.heartRate]),
        Sensor(id: UUID(), name: "Scosche Rhythm24", services: [.heartRate]),
    ]
    
    func sensors(withServices services: ([Sensor.Service])) -> AsyncStream<Sensor> {
        var iterator = sensors.makeIterator()

        return AsyncStream {
            try? await Task.sleep(for: .seconds(1))
            return iterator.next()
        }
    }
    
}
