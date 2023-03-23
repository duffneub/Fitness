//
//  BluetoothManager.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/21/23.
//

import CoreBluetooth
import Foundation

//final class BluetoothManager: NSObject, ObservableObject {
//
//    private var central: CBCentralManager!
//    private var stateContinuation: CheckedContinuation<CBManagerState, Never>?
//    private var scanContinuation: AsyncStream<CBPeripheral>.Continuation?
//    private var connectContinuation: [UUID: CheckedContinuation<Void, Error>] = [:]
//    private var servicesContinuation: CheckedContinuation<[CBService], Error>?
//    private var characteristicContinuations: [CBUUID: CheckedContinuation<[CBCharacteristic], Error>] = [:]
//    private var disconnectContinuation: [UUID: CheckedContinuation<Void, Error>] = [:]
//    
//    static let shared = BluetoothManager()
//    
//    var state: CBManagerState {
//        get async {
//            switch central.state {
//            case .unknown, .resetting:
//                return await withCheckedContinuation { continuation in
//                    self.stateContinuation = continuation
//                }
//            case .unsupported, .unauthorized, .poweredOff, .poweredOn:
//                return central.state
//            @unknown default:
//                fatalError("Unhandled: \(central.state)")
//            }
//        }
//    }
//
//    override init() {
//        super.init()
//
//        central = CBCentralManager(delegate: self, queue: nil)
//    }
//    
//    func scanForPeripherals(
//        withServices serviceUUIDs: [CBUUID]?, options: [String : Any]? = nil
//    ) -> AsyncStream<CBPeripheral> {
//        print("Start scan")
//        
//        return .init { continuation in
//            self.scanContinuation = continuation
//            Task {
//                guard await state == .poweredOn else {
//                    continuation.finish()
//                    return
//                }
//                
//                central.scanForPeripherals(withServices: serviceUUIDs, options: options)
//            }
//        }
//    }
//    
//    func stopScan() {
//        print("Stop scan")
//        central.stopScan()
//    }
//    
//    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheral] {
//        central.retrievePeripherals(withIdentifiers: identifiers)
//    }
//    
//    func connect(_ peripheral: CBPeripheral, options: [String : Any]? = nil) async throws {
//        print("Connecting to \(peripheral.name!)")
//        
//        try await withCheckedThrowingContinuation { continuation in
//            self.connectContinuation[peripheral.identifier] = continuation
//            central.connect(peripheral)
//        }
//        
//        print("Connected to '\(peripheral.name!)'")
//    }
//    
//    func cancelPeripheralConnection(_ peripheral: CBPeripheral) async throws {
//        print("Disconnecting from \(peripheral.name!)")
//        
//        try await withCheckedThrowingContinuation { continuation in
//            self.disconnectContinuation[peripheral.identifier] = continuation
//            central.cancelPeripheralConnection(peripheral)
//        }
//        
//        print("Disconnected from '\(peripheral.name!)'")
//    }
//    
//    func foo(_ sensor: Sensor, service: Sensor.Service = Sensor.Service.heartRate) {
//        guard let peripheral = central.retrievePeripherals(withIdentifiers: [sensor.id]).first else {
//            print("Unable to find peripheral: \(sensor.name)")
//            return
//        }
//        
//        Task {
//            do {
//                print("Connecting to \(sensor.name)")
//                
//                try await withCheckedThrowingContinuation { continuation in
//                    self.connectContinuation[peripheral.identifier] = continuation
//                    central.connect(peripheral)
//                }
//                
//                print("Connected to '\(sensor.name)'")
//                
//                print("\(sensor.name):")
//                if let services = peripheral.services {
//                    services.forEach { service in
//                        print("  * Service: \(service)")
//                        
//                        if let characteristics = service.characteristics {
//                            characteristics.forEach { characteristic in
//                                print("    * Characteristic: \(characteristic)")
//                            }
//                        } else {
//                            print("    * Characteristics: nil")
//                        }
//                    }
//                } else {
//                    print("  * Services: nil")
//                }
//                
//                peripheral.delegate = self
//                
//                let services = try await withCheckedThrowingContinuation { continuation in
//                    self.servicesContinuation = continuation
//                    peripheral.discoverServices(sensor.services.map(\.bluetoothID))
//                }
//                
//                print("Discovered \(services.count) services for '\(sensor.name)'")
//                
//                print("\(sensor.name):")
//                if let services = peripheral.services {
//                    services.forEach { service in
//                        print("  * Service: \(service)")
//                        
//                        if let characteristics = service.characteristics {
//                            characteristics.forEach { characteristic in
//                                print("    * Characteristic: \(characteristic)")
//                            }
//                        } else {
//                            print("    * Characteristics: nil")
//                        }
//                    }
//                } else {
//                    print("  * Services: nil")
//                }
//                
//                let characteristics = try await withThrowingTaskGroup(
//                    of: [CBCharacteristic].self,
//                    returning: [CBCharacteristic].self
//                ) { taskGroup in
//                    let service = services.first(where: { $0.uuid == service.bluetoothID })!
//                    taskGroup.addTask {
//                        let duff: [CBCharacteristic] = try await withCheckedThrowingContinuation { continuation in
//                            print("Discovering chars for \(service.uuid)")
//                            self.characteristicContinuations[service.uuid] = continuation
//                            peripheral.discoverCharacteristics(nil, for: service)
//                        }
//                        
//                        return duff
//                    }
//                    
//                    var foo: [[CBCharacteristic]] = []
//                    for try await chars in taskGroup {
//                        foo.append(chars)
//                    }
//                    
//                    return foo.flatMap { $0 }
//                }
//                
//                print("Discovered \(characteristics.count) characteristics for '\(sensor.name)'")
//                
//                print("\(sensor.name):")
//                if let services = peripheral.services {
//                    services.forEach { service in
//                        print("  * Service: \(service)")
//                        
//                        if let characteristics = service.characteristics {
//                            characteristics.forEach { characteristic in
//                                print("    * Characteristic: \(characteristic)")
//                            }
//                        } else {
//                            print("    * Characteristics: nil")
//                        }
//                    }
//                } else {
//                    print("  * Services: nil")
//                }
//                
//                try await withCheckedThrowingContinuation { continuation in
//                    self.disconnectContinuation[peripheral.identifier] = continuation
//                    central.cancelPeripheralConnection(peripheral)
//                }
//                
//                print("Disconnected from '\(sensor.name)'")
//            } catch {
//                print("Error somewhere in BLE land -- \(error)")
//            }
//        }
//    }
//
//}
//
//// MARK: - CBCentralManagerDelegate
//
//extension BluetoothManager: CBCentralManagerDelegate {
//
//    func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        switch central.state {
//        case .poweredOff:
//            print("Powered Off")
//        case .poweredOn:
//            print("Powered On")
//        case .resetting:
//            print("Resetting")
//        case .unauthorized:
//            print("Unauthorized")
//        case .unknown:
//            print("Unknown")
//        case .unsupported:
//            print("Unsupported")
//        @unknown default:
//            print("Some new unknown")
//        }
//        
//        stateContinuation?.resume(returning: central.state)
//    }
//    
//    func centralManager(
//        _ central: CBCentralManager,
//        didDiscover peripheral: CBPeripheral,
//        advertisementData: [String : Any],
//        rssi RSSI: NSNumber
//    ) {
//        print("Discovered \(peripheral.name!)")
//        scanContinuation?.yield(peripheral)
//    }
//    
//    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
//        connectContinuation[peripheral.identifier]?.resume()
//        connectContinuation.removeValue(forKey: peripheral.identifier)
//    }
//    
//    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
//        connectContinuation[peripheral.identifier]?.resume(throwing: error!)
//        connectContinuation.removeValue(forKey: peripheral.identifier)
//    }
//    
//    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
//        if let error = error {
//            disconnectContinuation[peripheral.identifier]?.resume(throwing: error)
//        } else {
//            disconnectContinuation[peripheral.identifier]?.resume()
//        }
//        
//        disconnectContinuation.removeValue(forKey: peripheral.identifier)
//    }
//
//}
//
//extension BluetoothManager: CBPeripheralDelegate {
//    
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
//        if let error = error {
//            servicesContinuation?.resume(throwing: error)
//        } else {
//            servicesContinuation?.resume(returning: peripheral.services!)
//        }
//    }
//    
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
//        if let error = error {
//            characteristicContinuations[service.uuid]?.resume(throwing: error)
//        } else {
//            characteristicContinuations[service.uuid]?.resume(returning: service.characteristics!)
//        }
//    }
//    
//}
//
//extension CBUUID {
//    
//    enum Service {
//        static let heartRate = CBUUID(string: "0x180D")
//    }
//    
////    static let cyclingPower = CBUUID(string: "0x1818")
////    static let cyclingSpeedCadence = CBUUID(string: "0x1816")
////    static let runningSpeedCadence = CBUUID(string: "0x1814")
////
////
////    static let heartRateMeasurement = CBUUID(string: "0x2A37")
////
////    static let cyclingPowerMeasurement = CBUUID(string: "0x2A63")
////    static let cyclingPowerFeature = CBUUID(string: "0x2A65")
////    static let sensorLocation = CBUUID(string: "0x2A5D")
////    static let cyclingPowerControlPoint = CBUUID(string: "0x2A66")
////
////    static let cscMeasurement = CBUUID(string: "0x2A5C")
////    static let cscFeature = CBUUID(string: "0x2A5B")
////
////    static let rscMeasurement = CBUUID(string: "0x2A53")
////    static let rscFeature = CBUUID(string: "0x2A54")
//}
//
//extension BluetoothManager: SensorStore {
//    
//    func sensors(withServices services: ([Sensor.Service])) -> AsyncStream<Sensor> {
//        scanForPeripherals(withServices: services.map(\.bluetoothID))
//            .map(Sensor.init)
//            .makeAsyncStream {
//                self.stopScan()
//            }
//    }
//    
//    func connect(to sensor: Sensor) async throws {
//        fatalError("`\(Self.self).\(#function)` is unimplemented")
//    }
//    
//    func disconnect(from sensor: Sensor) async throws {
//        fatalError("`\(Self.self).\(#function)` is unimplemented")
//    }
//    
//}
//
//View
//
//<Store>.discoverSensors()
//
//BluetoothStore
