//
//  SensorStore.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/21/23.
//

import SwiftUI

protocol SensorStore {
    
    func sensors(withServices services: ([Sensor.Service])) -> AsyncStream<Sensor>
    
}

struct DefaultSensorStore: SensorStore {
    
    func sensors(withServices services: ([Sensor.Service])) -> AsyncStream<Sensor> {
        fatalError("`\(Self.self).\(#function)` is unimplemented")
    }
    
}

extension SensorStore where Self == DefaultSensorStore {
    
    static var automatic: Self { Self() }
    
}

// MARK: - Environment

private struct SensorStoreKey: EnvironmentKey {
    static let defaultValue: SensorStore = .automatic
}

extension EnvironmentValues {
    
    var sensorStore: SensorStore {
        get { self[SensorStoreKey.self] }
        set { self[SensorStoreKey.self] = newValue }
    }

}

extension View {
    
    func sensorStore<S : SensorStore>(_ scanner: S) -> some View {
        environment(\.sensorStore, scanner)
    }
    
}

// MARK: - Helpers

extension AsyncSequence {
    
    func makeAsyncStream(onCancel: (() -> Void)? = nil) -> AsyncStream<Element> {
        var iterator = makeAsyncIterator()
        
        if let onCancel = onCancel {
            return AsyncStream {
                try? await iterator.next()
            } onCancel: {
                onCancel()
            }
        } else {
            return AsyncStream {
                try? await iterator.next()
            }
        }
    }
    
}
