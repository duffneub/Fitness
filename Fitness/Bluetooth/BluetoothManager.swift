//
//  BluetoothManager.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/21/23.
//

import CoreBluetooth
import Foundation

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
        print("Start scan")
        
        return .init { continuation in
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
        print("Stop scan")
        central.stopScan()
    }

}

// MARK: - CBCentralManagerDelegate

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
        print("Discovered \(peripheral.name!)")
        scanContinuation?.yield(peripheral)
    }

}

extension Sensor {
    
    init(_ peripheral: CBPeripheral) {
        self.init(
            id: peripheral.identifier,
            name: peripheral.name!,
            services: (peripheral.services ?? []).compactMap(Sensor.Service.init)
        )
    }
    
}

extension Sensor.Service {
    
    init?(_ service: CBService) {
        switch service.uuid {
        case CBUUID.Service.heartRate:
            self = .heartRate
        default:
            return nil
        }
    }
    
    var bluetoothID: CBUUID {
        switch self {
        case .heartRate:
            return CBUUID.Service.heartRate
        }
    }
    
}

extension CBUUID {
    
    enum Service {
        static let heartRate = CBUUID(string: "0x180D")
    }
    
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
