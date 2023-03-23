//
//  BluetoothSensorStore.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/21/23.
//

import CoreBluetooth
import Foundation

class BluetoothSensorStore: SensorStore {

    let bluetoothManager: BluetoothManager
    
    init(bluetoothManager: BluetoothManager) {
        self.bluetoothManager = bluetoothManager
    }
    
    private var peripherals: [UUID: CBPeripheral] = [:]
    
    func sensors(withServices services: ([Sensor.Service])) -> AsyncStream<Sensor> {
        bluetoothManager
            .scanForPeripherals(withServices: services.map(\.bluetoothID))
            .map {
                self.peripherals[$0.identifier] = $0
                return Sensor($0)
            }
            .makeAsyncStream {
                self.bluetoothManager.stopScan()
                self.peripherals = self.peripherals.filter { $0.value.state != .disconnected }
            }
    }
    
    func connect(to sensor: Sensor) async throws {
        enum ConnectError: Error, CustomStringConvertible {
            case retrievePeripheral
            
            var description: String {
                switch self {
                case .retrievePeripheral: return "Failed to retrieve peripheral"
                }
            }
        }
        guard let peripheral = peripherals[sensor.id] else {
            throw ConnectError.retrievePeripheral
        }
        
        try await bluetoothManager.connect(peripheral)
    }
    
    func disconnect(from sensor: Sensor) async throws {
        enum DisconnectError: Error, CustomStringConvertible {
            case retrievePeripheral
            
            var description: String {
                switch self {
                case .retrievePeripheral: return "Failed to retrieve peripheral"
                }
            }
        }
        guard let peripheral = peripherals[sensor.id] else {
            throw DisconnectError.retrievePeripheral
        }
        
        try await bluetoothManager.cancelPeripheralConnection(peripheral)
    }
    
}

extension SensorStore where Self == BluetoothSensorStore {
    
    static func bluetooth(_ manager: BluetoothManager) -> Self {
        Self(bluetoothManager: manager)
    }
    
}
