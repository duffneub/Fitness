//
//  Peripheral.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/30/23.
//

import CoreBluetooth

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
