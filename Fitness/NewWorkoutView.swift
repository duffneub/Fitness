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

struct Device {
    let id: UUID
    let name: String
}

extension Device: Identifiable {}

func findHeartRateMonitors() -> AsyncStream<Device> {
    .init { continuation in
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            continuation.yield(.init(id: UUID(), name: "Wahoo Tickr"))
            
            try? await Task.sleep(for: .seconds(1))
            continuation.yield(.init(id: UUID(), name: "Polar H9"))
            
            try? await Task.sleep(for: .seconds(1))
            continuation.yield(.init(id: UUID(), name: "Scosche Rhythm24"))
            
            continuation.finish()
        }
    }
}

struct FindDevicesView: View {
    
//    @Binding var selectedDevice: Device
    @State private var peripheralMap: [UUID: CBPeripheral] = [:]
    
    var peripherals: [CBPeripheral] {
        Array(peripheralMap.values)
    }
    
    @StateObject var bluetoothManager = BluetoothManager()
    
    var body: some View {
        List(peripherals, id: \.identifier) { peripheral in
            Text(peripheral.name!)
        }
        .navigationTitle("Devices…")
        .task {
            for await peripheral in bluetoothManager.scanForPeripherals(withServices: [.heartRateMonitor]) {
                peripheralMap[peripheral.identifier] = peripheral
            }
        }
        .onDisappear {
            bluetoothManager.stopScan()
        }
    }
    
}

import CoreBluetooth

final class BluetoothManager: NSObject, ObservableObject {

    private var central: CBCentralManager!
    private var stateContinuation: CheckedContinuation<CBManagerState, Never>?
    private var scanContinuation: AsyncStream<CBPeripheral>.Continuation?
    
    var state: CBManagerState {
        get async {
            switch central.state {
            case .unknown, .resetting:
                return await withCheckedContinuation { continuation in
                    self.stateContinuation = continuation
                }
            case .unsupported, .unauthorized, .poweredOff, .poweredOn:
                return central.state
            @unknown default:
                fatalError("Unhandled: \(central.state)")
            }
        }
    }

    override init() {
        super.init()

        central = CBCentralManager(delegate: self, queue: nil)
    }
    
    func scanForPeripherals(
        withServices serviceUUIDs: [CBUUID]?, options: [String : Any]? = nil
    ) -> AsyncStream<CBPeripheral> {
        .init { continuation in
            self.scanContinuation = continuation
            Task {
                guard await state == .poweredOn else {
                    continuation.finish()
                    return
                }
                
                central.scanForPeripherals(withServices: serviceUUIDs, options: options)
            }
        }
    }
    
    func stopScan() {
        central.stopScan()
    }

}

extension BluetoothManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            print("Powered Off")
        case .poweredOn:
            print("Powered On")
        case .resetting:
            print("Resetting")
        case .unauthorized:
            print("Unauthorized")
        case .unknown:
            print("Unknown")
        case .unsupported:
            print("Unsupported")
        @unknown default:
            print("Some new unknown")
        }
        
        stateContinuation?.resume(returning: central.state)
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        scanContinuation?.yield(peripheral)
    }

}

extension CBUUID {
    
    static let heartRateMonitor = CBUUID(string: "0x180D")
//    static let cyclingPower = CBUUID(string: "0x1818")
//    static let cyclingSpeedCadence = CBUUID(string: "0x1816")
//    static let runningSpeedCadence = CBUUID(string: "0x1814")
//
//
//    static let heartRateMeasurement = CBUUID(string: "0x2A37")
//
//    static let cyclingPowerMeasurement = CBUUID(string: "0x2A63")
//    static let cyclingPowerFeature = CBUUID(string: "0x2A65")
//    static let sensorLocation = CBUUID(string: "0x2A5D")
//    static let cyclingPowerControlPoint = CBUUID(string: "0x2A66")
//
//    static let cscMeasurement = CBUUID(string: "0x2A5C")
//    static let cscFeature = CBUUID(string: "0x2A5B")
//
//    static let rscMeasurement = CBUUID(string: "0x2A53")
//    static let rscFeature = CBUUID(string: "0x2A54")
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

struct NewWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack(path: .constant(.init([1]))) {
            NewWorkoutView(activity: .indoorRide)
        }
        .onAddWorkout { _ in }
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
