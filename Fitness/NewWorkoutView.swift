//
//  NewWorkoutView.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/9/23.
//

import CoreBluetooth
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
    
    private let bluetoothStore = BluetoothStore()
    @State private var selectecPeripheral: CBPeripheral?
    
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
                
                NavigationLink {
                    FindDevicesView(services: [CBUUID.Service.heartRate], selection: $selectecPeripheral, bluetoothStore: bluetoothStore)
                } label: {
                    if let peripheral = selectecPeripheral {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Heart Rate")
                                    .font(.headline)
                                Text(peripheral.name!)
                                    .font(.caption)
                            }
                            Spacer()
                            
                            CharacteristicView(
                                peripheral: .init(peripheral),
                                service: CBUUID.Service.heartRate,
                                characteristic: CBUUID.Characteristic.heartRateMeasurement,
                                bluetoothStore: bluetoothStore
                            ) { value in
                                guard let value = value, let flags = value.first else { return "--" }

                                let is16Bit = (flags & 0b10000000) != 0
                                let bpm = is16Bit
                                    ? Int(value[1...2].withUnsafeBytes { $0.load(as: UInt16.self) })
                                    : Int(value[1])

                                return "\(bpm) bpm"
                            }
                        }
                    } else {
                        HStack {
                            Text("Heart Rate")
                                .font(.headline)
                            Spacer()
                            
                            Text("Search")
                        }
                    }
                }
            }
            
            Spacer()
            
            StartStopControls(status: $status)
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
        .onDisappear {
            Task {
                if let peripheral = selectecPeripheral {
                    try? await bluetoothStore.cancelPeripheralConnection(peripheral)
                }
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

struct CharacteristicView: View {
    
    let peripheral: Peripheral
    let service: CBUUID
    let characteristic: CBUUID
    let bluetoothStore: BluetoothStore
    let formatter: (Data?) -> String
    
    @State private var value: String = "--"
    
    var body: some View {
        Text(value)
            .task {
                do {
                    let service = try await peripheral.discoverServices([service])
                        .first(where: { $0.uuid == self.service })!
                    let characteristic = try await peripheral.discoverCharacteristics([characteristic], for: service)
                        .first(where: { $0.uuid == self.characteristic })!
                    for try await value in peripheral.value(for: characteristic) {
                        self.value = formatter(value)
                    }
                } catch {
                    print("Failed -- \(error)")
                }
            }
    }
    
}

struct SensorView: View {
    
    let sensor: Sensor
    let service: Sensor.Service
    
    @State var value: Int = 0
    
    @Environment(\.sensorStore) var sensorStore
    
    var body: some View {
        Text("\(value)")
            .task {
//                for await bpm in sensor.traits(\.heartRate) {
//                    value = bpm
//                }
//                !! Does this service store have everything already discovered?
//                !! Then we're just observing values for a service?
//                !! Is sensor a store?
//                !! Sensor can be a value and a store right? Cause SensorScanner is
//
//                for await value in sensor.value(for: service) {
                    // connect
                    
                    // discover service
                    
                    // discover characteristc on service
                    
                    // notify
                    
                    // disconnect on cancel
//                }
            }
            .onAppear {
                
                print("Sensor: \(sensor)")
            }
        
        // Get characteristic from Sensor.Service
        // Observe changes
        // Convert value to string
        
        // get peripheral
            // retirve peripheral with UUID
            // connect to peripheral
            // discover service
            // discover char
        // observe value for a characteristic
            // notify
        // convert value to string
            // ?
    }
    
}

class Peripheral: NSObject, ObservableObject {
    
    let peripheral: CBPeripheral
    
    private var stateObservation: NSKeyValueObservation!
    private var servicesContinuation: CheckedContinuation<[CBService], Error>?
    private var characteristicsContinuation: [CBUUID: CheckedContinuation<[CBCharacteristic], Error>] = [:]
    private var characteristicValueContinuation: [CBUUID: AsyncThrowingStream<Data?, Error>.Continuation] = [:]
    
    init(_ peripheral: CBPeripheral) {
        self.peripheral = peripheral
        
        super.init()
        
        self.stateObservation = self.peripheral.observe(\.state) { _, _ in
            self.objectWillChange.send()
        }
    }
    
    func discoverServices(_ serviceUUIDs: [CBUUID]?) async throws -> [CBService] {
        let services = try await withCheckedThrowingContinuation { continuation in
            self.servicesContinuation = continuation
            print("Discovering service for \(peripheral.name!)")
            peripheral.delegate = self
            peripheral.discoverServices(serviceUUIDs)
        }
        print("Discovered \(peripheral.services?.count ?? 0) services for '\(peripheral.name!)'")
        return services
    }
    
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService) async throws -> [CBCharacteristic] {
        let characteristics = try await withCheckedThrowingContinuation { continuation in
            characteristicsContinuation[service.uuid] = continuation
            print("Discovering characteristics for \(service.description) of \(peripheral.name!)")
            peripheral.delegate = self
            peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
        }
        print("Discovered \(service.characteristics?.count ?? 0) characteristics for \(service.description) of \(peripheral.name!)")
        
        return characteristics
    }
    
    func value(for characteristic: CBCharacteristic) -> AsyncThrowingStream<Data?, Error> {
        AsyncThrowingStream<Data?, Error> { continuation in
            characteristicValueContinuation[characteristic.uuid] = continuation
            continuation.onTermination = { @Sendable [weak self] _ in
                self?.peripheral.setNotifyValue(false, for: characteristic)
            }
            print("Observe value for \(characteristic.description) of \(peripheral.name!)")
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
    
}

extension Peripheral: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            servicesContinuation?.resume(throwing: error)
        } else {
            servicesContinuation?.resume(returning: peripheral.services ?? [])
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            characteristicsContinuation[service.uuid]?.resume(throwing: error)
        } else {
            characteristicsContinuation[service.uuid]?.resume(returning: service.characteristics ?? [])
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            characteristicValueContinuation[characteristic.uuid]?.finish(throwing: error)
        } else {
            characteristicValueContinuation[characteristic.uuid]?.yield(characteristic.value)
        }
    }
    
}

struct FindDevicesView: View {
    
    let services: [CBUUID]
    @Binding var selection: CBPeripheral?
    let bluetoothStore: BluetoothStore
    
    @State private var peripheralMap: [UUID: CBPeripheral] = [:]
    
    var peripherals: [CBPeripheral] {
        Array(peripheralMap.values)
    }
    
    var body: some View {
        List(peripherals, id: \.identifier) { peripheral in
            Button {
                Task {
                    
                    if peripheral.state == .disconnected {
                        do {
                            try await bluetoothStore.connect(peripheral)
                            selection = peripheral
                        } catch {
                            print("Failed to connect to '\(peripheral.name!)' -- \(error)")
                        }
                    } else {
                        do {
                            try await bluetoothStore.cancelPeripheralConnection(peripheral)
                            selection = nil
                        } catch {
                            print("Failed to connect to '\(peripheral.name!)' -- \(error)")
                        }
                    }
                }
            } label: {
                HStack {
                    Text(peripheral.name!)
                    Spacer()
                    
                    switch peripheral.state {
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
            .foregroundColor(.primary)
                
        }
        .navigationTitle("Devices…")
        .task {
            for await peripheral in bluetoothStore.peripherals(withServices: services) {
                peripheralMap[peripheral.identifier] = peripheral
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
        NavigationStack {
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
    
    func connect(to sensor: Sensor) async throws {
        try await Task.sleep(for: .seconds(1))
    }
    
    func disconnect(from sensor: Sensor) async throws {
        try await Task.sleep(for: .seconds(1))
    }
    
}

extension SensorStore where Self == PreviewSensorStore {
    
    static var preview: Self { Self() }
    
}
