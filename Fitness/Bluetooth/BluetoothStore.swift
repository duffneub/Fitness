//
//  BluetoothStore.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/21/23.
//

import CoreBluetooth
import Foundation

class BluetoothStore: NSObject {

    private var central: CBCentralManager!
    
    private var stateContinuation: CheckedContinuation<CBManagerState, Never>?
    private var scanContinuation: AsyncStream<CBPeripheral>.Continuation?
    private var connectContinuation: [UUID: CheckedContinuation<Void, Error>] = [:]
    private var disconnectContinuation: [UUID: CheckedContinuation<Void, Error>] = [:]
    
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
    
}

extension BluetoothStore {
    
    func peripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]? = nil) -> AsyncStream<CBPeripheral> {
        AsyncStream<CBPeripheral> { continuation in
            self.scanContinuation?.finish()
            self.scanContinuation = continuation
            Task {
                guard await state == .poweredOn else {
                    continuation.finish()
                    return
                }
                
                continuation.onTermination = { @Sendable _ in
                    print("Stop scan")
                    self.central.stopScan()
                }

                print("Start scan")
                central.scanForPeripherals(withServices: serviceUUIDs)
            }
        }
        .makeAsyncStream {
            self.central.stopScan()
        }
    }
    
    func connect(_ peripheral: CBPeripheral, options: [String : Any]? = nil) async throws {        
        try await withCheckedThrowingContinuation { continuation in
            self.connectContinuation[peripheral.identifier] = continuation
            print("Connecting to \(peripheral.name!)")
            central.connect(peripheral)
        }
        print("Connected to '\(peripheral.name!)'")
    }
    
    func cancelPeripheralConnection(_ peripheral: CBPeripheral) async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.disconnectContinuation[peripheral.identifier] = continuation
            print("Disconnecting from \(peripheral.name!)")
            central.cancelPeripheralConnection(peripheral)
        }
        print("Disconnected from '\(peripheral.name!)'")
    }
    
}

// MARK: - CBCentralManagerDelegate

extension BluetoothStore: CBCentralManagerDelegate {

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
        print("Discovered \(peripheral.name!)")
        scanContinuation?.yield(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectContinuation[peripheral.identifier]?.resume()
        connectContinuation.removeValue(forKey: peripheral.identifier)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectContinuation[peripheral.identifier]?.resume(throwing: error!)
        connectContinuation.removeValue(forKey: peripheral.identifier)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            disconnectContinuation[peripheral.identifier]?.resume(throwing: error)
        } else {
            disconnectContinuation[peripheral.identifier]?.resume()
        }
        
        disconnectContinuation.removeValue(forKey: peripheral.identifier)
    }

}

//extension BluetoothStore: SensorStore {
//    
//    func sensors(withServices services: ([Sensor.Service])) -> AsyncStream<Sensor> {
//        AsyncStream<CBPeripheral> { continuation in
//            self.scanContinuation?.finish()
//            self.scanContinuation = continuation
//            Task {
//                guard await state == .poweredOn else {
//                    continuation.finish()
//                    return
//                }
//
//                print("Start scan")
//                central.scanForPeripherals(withServices: services.map(\.bluetoothID))
//            }
//        }
//        .map(Sensor.init)
//        .makeAsyncStream {
//            self.central.stopScan()
//            self.peripherals = self.peripherals.filter { $0.value.state != .disconnected }
//        }
//    }
//    
//    func connect(to sensor: Sensor) async throws {
//        enum ConnectError: Error, CustomStringConvertible {
//            case retrievePeripheral
//            
//            var description: String {
//                switch self {
//                case .retrievePeripheral: return "Failed to retrieve peripheral"
//                }
//            }
//        }
//        guard let peripheral = peripherals[sensor.id] else {
//            throw ConnectError.retrievePeripheral
//        }
//        
//        print("Connecting to \(peripheral.name!)")
//        try await withCheckedThrowingContinuation { continuation in
//            self.connectContinuation[peripheral.identifier] = continuation
//            central.connect(peripheral)
//        }
//        print("Connected to '\(peripheral.name!)'")
//    }
//    
//    func disconnect(from sensor: Sensor) async throws {
//        enum DisconnectError: Error, CustomStringConvertible {
//            case retrievePeripheral
//            
//            var description: String {
//                switch self {
//                case .retrievePeripheral: return "Failed to retrieve peripheral"
//                }
//            }
//        }
//        guard let peripheral = peripherals[sensor.id] else {
//            throw DisconnectError.retrievePeripheral
//        }
//        
//        print("Disconnecting from \(peripheral.name!)")
//        try await withCheckedThrowingContinuation { continuation in
//            self.disconnectContinuation[peripheral.identifier] = continuation
//            central.cancelPeripheralConnection(peripheral)
//        }
//        print("Disconnected from '\(peripheral.name!)'")
//    }
//    
//}
//
//extension SensorStore where Self == BluetoothStore {
//    
//    static var bluetooth: Self { Self() }
//    
//}
//
//extension Sensor {
//    
//    init(_ peripheral: CBPeripheral) {
//        self.init(
//            id: peripheral.identifier,
//            name: peripheral.name!,
//            services: (peripheral.services ?? []).compactMap(Sensor.Service.init)
//        )
//    }
//    
//}
//
//extension Sensor.Service {
//    
//    init?(_ service: CBService) {
//        switch service.uuid {
//        case CBUUID.Service.heartRate:
//            self = .heartRate
//        default:
//            return nil
//        }
//    }
//    
//    var bluetoothID: CBUUID {
//        switch self {
//        case .heartRate:
//            return CBUUID.Service.heartRate
//        }
//    }
//    
//}

extension CBUUID {
    
    enum Service {
        static let heartRate = CBUUID(string: "0x180D")
        static let cyclingPower = CBUUID(string: "0x1818")
    }
    
    enum Characteristic {
        static let heartRateMeasurement = CBUUID(string: "0x2A37")
        static let cyclingPowerMeasurement = CBUUID(string: "0x2A63")
    }
    
//    static let cyclingSpeedCadence = CBUUID(string: "0x1816")
//    static let runningSpeedCadence = CBUUID(string: "0x1814")
//
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
