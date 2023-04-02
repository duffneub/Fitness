//
//  NewWorkoutView.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/9/23.
//

import CoreBluetooth
import SwiftUI

struct Sample: Equatable, Codable, Hashable {
    let date: Date
    let metric: Workout.Metric
    let value: Int
    
    init(metric: Workout.Metric, value: Int) {
        self.date = Date()
        self.metric = metric
        self.value = value
    }
}

extension Sample: CustomStringConvertible {
    
    var description: String {
        metric.description(value)
    }
    
}

class WorkoutBuilder: ObservableObject {
    
    enum Status {
        case ready
        case inProgress
        case paused
        case complete
    }
    
    let activity: Activity
    
    @Published var samples: [Sample] = []

    @Published private(set) var duration: Duration = .milliseconds(0)
    @Published private(set) var status: Status = .ready
    
    private var start: Date?
    private var accumulatedTime: Duration =  .milliseconds(0)
    private var timer: Timer?
    
    
    init(activity: Activity) {
        self.activity = activity
    }
    
    func startWorkout() {
        guard start == nil else { return }
        let now = Date()
        start = now
        
        timer = .scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            let seconds = Date().timeIntervalSince(now)
            self.duration = self.accumulatedTime + .seconds(seconds)
        }
        status = .inProgress
    }
    
    func pause() {
        timer?.invalidate()
        accumulatedTime = duration
        status = .paused
    }
    
    func resume() {
        let now = Date()
        
        timer = .scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            let seconds = Date().timeIntervalSince(now)
            self.duration = self.accumulatedTime + .seconds(seconds)
        }
        status = .inProgress
    }
    
    func stopWorkout() -> Workout {
        status = .complete
        let end = Date()
        return Workout(activity: activity, start: start ?? end, end: end, activeDuration: duration, samples: samples)
    }
    
}

@MainActor
class PeripheralManager: ObservableObject {
    
    let bluetoothStore: BluetoothStore
    
    var peripherals: [Something] {
        Array(peripheralMap.values)
    }
    
    @Published var selectedPeripherals: [CBUUID: CBPeripheral] = [:]
    
    @Published private var peripheralMap: [UUID: Something] = [:]
    
    init(bluetoothStore: BluetoothStore) {
        self.bluetoothStore = bluetoothStore
    }
    
    func discoverPeripherals(withService service: CBUUID) async {
        for await peripheral in bluetoothStore.peripherals(withServices: [service]) {
            peripheralMap[peripheral.identifier] = Something(peripheral: .init(peripheral))
        }
    }
    
    func toggleConnection(_ something: Something, for service: CBUUID) {
        let peripheral = something.peripheral.peripheral
        Task {
            if peripheral.state == .disconnected {
                do {
                    
                    try await bluetoothStore.connect(peripheral)
                    selectedPeripherals[service] = peripheral
                } catch {
                    print("Failed to connect to '\(peripheral.name!)' -- \(error)")
                }
            } else {
                do {
                    try await bluetoothStore.cancelPeripheralConnection(peripheral)
                    selectedPeripherals[service] = nil
                } catch {
                    print("Failed to connect to '\(peripheral.name!)' -- \(error)")
                }
            }
        }
    }
    
    func something(for metric: Workout.Metric) -> Something? {
        guard let peripheral = selectedPeripherals[metric.serviceID] else { return nil}
        
        return Something(peripheral: .init(peripheral))
    }
    
    func disconnectAllDevices() {
        if let peripheral = selectedPeripherals[CBUUID.Service.heartRate],
           let service = peripheral.services?.first(where: { $0.uuid == CBUUID.Service.heartRate }),
           let char = service.characteristics?.first(where: { $0.uuid == CBUUID.Characteristic.heartRateMeasurement })
        {
            print("Stop observing \(char.description) of \(peripheral.name!)")
            peripheral.setNotifyValue(false, for: char)
            Task {
                try? await bluetoothStore.cancelPeripheralConnection(peripheral)
            }
        }
        
        if let peripheral = selectedPeripherals[CBUUID.Service.cyclingPower],
           let service = peripheral.services?.first(where: { $0.uuid == CBUUID.Service.cyclingPower }),
           let char = service.characteristics?.first(where: { $0.uuid == CBUUID.Characteristic.cyclingPowerMeasurement })
        {
            print("Stop observing \(char.description) of \(peripheral.name!)")
            peripheral.setNotifyValue(false, for: char)
            Task {
                try? await bluetoothStore.cancelPeripheralConnection(peripheral)
            }
        }
    }
    
}

struct NewWorkoutView: View {
    
    @Environment(\.addWorkout) var addWorkout
    
    @Environment(\.isPresented) var isPresented
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject private var builder: WorkoutBuilder
    @ObservedObject private var peripheralManager: PeripheralManager
    
    let bluetoothStore: BluetoothStore
    
    init(activity: Activity, bluetoothStore: BluetoothStore) {
        self.builder = .init(activity: activity)
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
                    Text(builder.duration.formatted())
                }
                
                WorkoutMetricView(peripheralManager: peripheralManager, bluetoothStore: bluetoothStore, samples: $builder.samples, metric: .heartRate)
                
                WorkoutMetricView(peripheralManager: peripheralManager, bluetoothStore: bluetoothStore, samples: $builder.samples, metric: .power)
            }
            
            Spacer()
            
            Group {
                switch builder.status {
                case .ready:
                    Button("Start") {
                        builder.startWorkout()
                    }
                case .inProgress:
                    Button("Pause") {
                        builder.pause()
                    }
                case .paused:
                    HStack {
                        Button("Resume") {
                            builder.resume()
                        }
                        .buttonStyle(BorderedButtonStyle())
                        
                        Button("Stop") {
                            let workout = builder.stopWorkout()
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
        .navigationTitle(builder.activity.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Dismiss") {
                    Task {
                        _ = builder.stopWorkout()
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
            FindDevicesView(service: metric.serviceID, peripheralManager: peripheralManager)
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

extension Workout {
    
    enum Metric: Equatable, Codable, Hashable {
        case heartRate
        case power
    }
    
}

extension Workout.Metric {
    
    var title: String {
        switch self {
        case .heartRate:
            return "Heart Rate"
        case .power:
            return "Power"
        }
    }
    
    func description(_ value: Int) -> String {
        switch self {
        case .heartRate:
            return "\(value) bpm"
        case .power:
            return "\(value) watts"
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

            let is16Bit = (flags & 0b10000000) != 0
            let bpm = is16Bit
                ? Int(value[1...2].withUnsafeBytes { $0.load(as: UInt16.self) })
                : Int(value[1])
            
            print("value: \(value)")
            print("flags: \(flags)")
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

@MainActor
class Something: ObservableObject {
    
    let peripheral: Peripheral
    
    private var observation: NSKeyValueObservation?
    
    var name: String {
        peripheral.peripheral.name!
    }
    
    var state: CBPeripheralState {
        return peripheral.peripheral.state
    }
    
    init(peripheral: Peripheral) {
        self.peripheral = peripheral
        
        observation = peripheral.peripheral.observe(\.state) { peripheral, _ in
            Task { @MainActor in
                self.objectWillChange.send()
            }
        }
    }
    
    func samples(for metric: Workout.Metric) -> AsyncStream<Sample?> {
        AsyncStream<Sample?> { continuation in
            Task {
                do {
                    let service = try await peripheral.discoverServices([metric.serviceID])
                        .first(where: { $0.uuid == metric.serviceID })!
                    let characteristic = try await peripheral.discoverCharacteristics([metric.characteristicID], for: service)
                        .first(where: { $0.uuid == metric.characteristicID })!
                    for try await value in peripheral.value(for: characteristic) {
                        guard let value = metric.format(value) else { continue }
                        continuation.yield(.init(metric: metric, value: value))
                    }
                } catch {
                    print("Failed -- \(error)")
                }
            }
        }
    }
    
}

struct FindDevicesView: View {
    
    let service: CBUUID
    @ObservedObject var peripheralManager: PeripheralManager
    
    var body: some View {
        List(peripheralManager.peripherals, id: \.peripheral.peripheral) { peripheral in
            Button {
                peripheralManager.toggleConnection(peripheral, for: service)
            } label: {
                DeviceView(something: peripheral)
            }
            .foregroundColor(.primary)
                
        }
        .navigationTitle("Devices…")
        .task {
            await peripheralManager.discoverPeripherals(withService: service)
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

struct Sensor: Identifiable {
    
    enum Service {
        case heartRate
    }
    
    enum State {
        case disconnected
        case connecting
        case connected
        case disconnecting
    }
    
    let id: UUID
    let name: String
    let services: [Service]
    
    var state: State = .disconnected
    
}

extension Sensor: Equatable {}
extension Sensor.Service: Equatable {}

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
