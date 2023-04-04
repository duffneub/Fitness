//
//  PeripheralManager.swift
//  Fitness
//
//  Created by Duff Neubauer on 4/3/23.
//

import CoreBluetooth
import Foundation

@MainActor
class PeripheralManager: ObservableObject {
    
    let bluetoothStore: BluetoothStore
    
    var peripherals: [Something] {
        Array(peripheralMap.values)
    }
    
    @Published var selectedPeripherals: [Workout.Metric: Something] = [:]
    
    @Published private var peripheralMap: [UUID: Something] = [:]
    
    init(bluetoothStore: BluetoothStore) {
        self.bluetoothStore = bluetoothStore
    }
    
    func discoverPeripherals(withMetric metric: Workout.Metric) async {
        for await (peripheral, serviceIDs) in bluetoothStore.peripherals(withServices: [metric.serviceID]) {
            peripheralMap[peripheral.identifier] = Something(peripheral: .init(peripheral), serviceIDs: serviceIDs)
        }
    }
    
    func peripherals(withMetric metric: Workout.Metric) -> [Something] {
        Array(peripheralMap.values).filter { $0.serviceIDs.contains(metric.serviceID) }
    }
    
    func toggleConnection(_ something: Something, for metric: Workout.Metric) {
        let peripheral = something.peripheral.peripheral
        Task {
            if peripheral.state == .disconnected {
                do {
                    
                    try await bluetoothStore.connect(peripheral)
                    selectedPeripherals[metric] = something
                } catch {
                    print("Failed to connect to '\(something.name)' -- \(error)")
                }
            } else {
                do {
                    try await bluetoothStore.cancelPeripheralConnection(peripheral)
                    selectedPeripherals[metric] = nil
                } catch {
                    print("Failed to connect to '\(something.name)' -- \(error)")
                }
            }
        }
    }
    
    func something(for metric: Workout.Metric) -> Something? {
        selectedPeripherals[metric]
    }
    
    func disconnectAllDevices() {
        if let peripheral = selectedPeripherals[.heartRate]?.peripheral.peripheral,
           let service = peripheral.services?.first(where: { $0.uuid == CBUUID.Service.heartRate }),
           let char = service.characteristics?.first(where: { $0.uuid == CBUUID.Characteristic.heartRateMeasurement })
        {
            print("Stop observing \(char.description) of \(peripheral.name!)")
            peripheral.setNotifyValue(false, for: char)
            Task {
                try? await bluetoothStore.cancelPeripheralConnection(peripheral)
            }
        }
        
        if let peripheral = selectedPeripherals[.power]?.peripheral.peripheral,
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
