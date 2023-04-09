//
//  NewWorkoutView.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/9/23.
//

import CoreBluetooth
import SwiftUI

struct NewWorkoutView: View {
    
    @Environment(\.addWorkout) var addWorkout
    
    @Environment(\.isPresented) var isPresented
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject private var session: WorkoutSession
    @ObservedObject private var peripheralManager: PeripheralManager
    
    let bluetoothStore: BluetoothStore
    
    init(activity: Activity, bluetoothStore: BluetoothStore) {
        self.session = .init(activity: activity)
        self.peripheralManager = .init(bluetoothStore: bluetoothStore)
        self.bluetoothStore = bluetoothStore
    }
    
    var body: some View {
        VStack {
            List {
                HStack {
                    Text("Duration")
                        .font(.headline)
                    Spacer()
                    Text(session.duration.formatted())
                }
                
                WorkoutMetricView(peripheralManager: peripheralManager, bluetoothStore: bluetoothStore, samples: $session.samples, metric: .heartRate)
                
                WorkoutMetricView(peripheralManager: peripheralManager, bluetoothStore: bluetoothStore, samples: $session.samples, metric: .power)
            }
            
            Spacer()
            
            Group {
                switch session.status {
                case .ready:
                    Button("Start") {
                        session.start()
                    }
                case .inProgress:
                    Button("Pause") {
                        session.pause()
                    }
                case .paused:
                    HStack {
                        Button("Resume") {
                            session.resume()
                        }
                        .buttonStyle(BorderedButtonStyle())
                        
                        Button("Stop") {
                            let workout = session.stop()
                            addWorkout(workout)
                            peripheralManager.disconnectAllDevices()
                            
                            if isPresented {
                                Task { @MainActor in
                                    try? await Task.sleep(for: .seconds(0.3))
                                    dismiss()
                                }
                            }
                        }
                    }
                case .complete:
                    EmptyView()
                }
            }
            .buttonStyle(BorderedProminentButtonStyle())
            .controlSize(.large)
        }
        .navigationTitle(session.activity.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Dismiss") {
                    Task {
                        _ = session.stop()
                        peripheralManager.disconnectAllDevices()

                        if isPresented {
                            Task { @MainActor in
                                try? await Task.sleep(for: .seconds(0.3))
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
}

struct WorkoutMetricView: View {
    
    @ObservedObject var peripheralManager: PeripheralManager
    let bluetoothStore: BluetoothStore
    @Binding var samples: [Sample]
    let metric: Workout.Metric
    
    @State private var latestSample: Sample?
    
    var body: some View {
        NavigationLink {
            FindDevicesView(metric: metric, peripheralManager: peripheralManager)
        } label: {
            if let something = peripheralManager.something(for: metric) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(metric.title)")
                            .font(.headline)
                        Text(something.peripheral.peripheral.name!)
                            .font(.caption)
                    }
                    Spacer()
                    
                    Text("\(latestSample?.description ?? "--")")
                }
                .task {
                    for await sample in something.samples(for: metric) {
                        if let sample {
                            samples.append(sample)
                            self.latestSample = sample
                        }
                    }
                    
                    
                }
            } else {
                HStack {
                    Text("\(metric.title)")
                        .font(.headline)
                    Spacer()
                    
                    Text("Search")
                }
            }
        }
    }
    
}

extension Workout.Metric {
    
    var serviceID: CBUUID {
        switch self {
        case .heartRate:
            return CBUUID.Service.heartRate
        case .power:
            return CBUUID.Service.cyclingPower
        }
    }
    
    var characteristicID: CBUUID {
        switch self {
        case .heartRate:
            return CBUUID.Characteristic.heartRateMeasurement
        case .power:
            return CBUUID.Characteristic.cyclingPowerMeasurement
        }
    }
    
    func format(_ value: Data?) -> Int? {
        switch self {
        case .heartRate:
            guard let value = value, let flags = value.first else { return nil }
            
            print("value: \(value)")
            print("flags: \(flags)")

            let isContactSupported = (flags & 0b00000010) != 0
            let isContactDetected = (flags & 0b00000100) != 0
            
            guard isContactSupported && isContactDetected else {
                print("Contact is not detected")
                return nil
            }
            
            let is16Bit = (flags & 0b00000001) != 0
            let bpm = is16Bit
                ? Int(value[1...2].withUnsafeBytes { $0.load(as: UInt16.self) })
                : Int(value[1])
            
            print("is16Bit: \(is16Bit)")
            
            print("\(title):")
            for duff in value.enumerated() {
                print("value[\(duff.offset)] = \(duff.element)")
            }
            print("")
            
            return bpm
        case .power:
            guard let value = value else { return nil }
            
            let power = Int(value[2...3].withUnsafeBytes { $0.load(as: UInt16.self) })
            
            print("\(title):")
            for duff in value.enumerated() {
                print("value[\(duff.offset)] = \(duff.element)")
            }
            print("")
            
            return power
        }
    }
    
}

extension CBPeripheralState: CustomStringConvertible {
    
    public var description: String {
        
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .disconnecting:
            return "Disconnecting"
        @unknown default:
            return "Unknown"
        }
        
    }
    
}

struct FindDevicesView: View {
    
    let metric: Workout.Metric
    @ObservedObject var peripheralManager: PeripheralManager
    
    var body: some View {
        List(peripheralManager.peripherals(withMetric: metric), id: \.peripheral.peripheral) { peripheral in
            Button {
                peripheralManager.toggleConnection(peripheral, for: metric)
            } label: {
                DeviceView(something: peripheral)
            }
            .foregroundColor(.primary)
                
        }
        .navigationTitle("Devices…")
        .task {
            await peripheralManager.discoverPeripherals(withMetric: metric)
        }
    }
    
}

struct DeviceView: View {
    
    @ObservedObject var something: Something
    
    var body: some View {
        HStack {
            Text(something.name)
            Spacer()
            
            switch something.state {
            case .disconnected:
                EmptyView()
            case .connecting:
                ProgressView()
            case .connected:
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
            case .disconnecting:
                EmptyView()
            @unknown default:
                EmptyView()
            }
        }
    }
    
}

// MARK: - Preview

//struct NewWorkoutView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationStack {
//            NewWorkoutView(activity: .indoorRide)
//        }
//        .onAddWorkout { _ in }
//        .sensorStore(.preview)
//    }
//}
//
//struct PreviewSensorStore: SensorStore {
//
//    let sensors: [Sensor] = [
//        Sensor(id: UUID(), name: "Wahoo Tickr", services: [.heartRate]),
//        Sensor(id: UUID(), name: "Polar H9", services: [.heartRate]),
//        Sensor(id: UUID(), name: "Scosche Rhythm24", services: [.heartRate]),
//    ]
//
//    func sensors(withServices services: ([Sensor.Service])) -> AsyncStream<Sensor> {
//        var iterator = sensors.makeIterator()
//
//        return AsyncStream {
//            try? await Task.sleep(for: .seconds(1))
//            return iterator.next()
//        }
//    }
//
//    func connect(to sensor: Sensor) async throws {
//        try await Task.sleep(for: .seconds(1))
//    }
//
//    func disconnect(from sensor: Sensor) async throws {
//        try await Task.sleep(for: .seconds(1))
//    }
//
//}
//
//extension SensorStore where Self == PreviewSensorStore {
//
//    static var preview: Self { Self() }
//
//}
