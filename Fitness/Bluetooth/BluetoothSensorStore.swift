//
//  BluetoothSensorStore.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/21/23.
//

import CoreBluetooth
import Foundation

struct BluetoothSensorStore: SensorStore {

    let bluetoothManager: BluetoothManager
    
    func sensors(withServices services: ([Sensor.Service])) -> AsyncStream<Sensor> {
        bluetoothManager
            .scanForPeripherals(withServices: services.map(\.bluetoothID))
            .map(Sensor.init)
            .makeAsyncStream {
                
                bluetoothManager.stopScan()
            }
    }
    
}

extension SensorStore where Self == BluetoothSensorStore {
    
    static func bluetooth(_ manager: BluetoothManager) -> Self {
        Self(bluetoothManager: manager)
    }
    
}
