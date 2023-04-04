//
//  Something.swift
//  Fitness
//
//  Created by Duff Neubauer on 4/3/23.
//

import CoreBluetooth
import Foundation

@MainActor
class Something: ObservableObject {
    
    let peripheral: Peripheral
    let serviceIDs: [CBUUID]
    
    private var observation: NSKeyValueObservation?
    
    var name: String {
        peripheral.peripheral.name!
    }
    
    var state: CBPeripheralState {
        return peripheral.peripheral.state
    }
    
    init(peripheral: Peripheral, serviceIDs: [CBUUID]) {
        self.peripheral = peripheral
        self.serviceIDs = serviceIDs
        
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
