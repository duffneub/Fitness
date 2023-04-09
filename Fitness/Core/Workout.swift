//
//  Workout.swift
//  Fitness
//
//  Created by Duff Neubauer on 4/3/23.
//

import Foundation

struct Workout: Identifiable {
    
    struct Event: Equatable, Codable, Hashable {
        
        enum `Type`: Equatable, Codable, Hashable {
            case pause
            case resume
        }
        
        let date: Date
        let type: `Type`
    }
    
    let id: UUID
    let activity: Activity
    let start: Date
    let end: Date
    
    private let samples: [Sample]
    let events: [Event]
    
    var totalDuration: Duration {
        let seconds = end.timeIntervalSince(start)
        return .seconds(seconds)
    }
    
    var activeDuration: Duration {
        var activeDuration: TimeInterval = 0
        var lastResume = start

        for event in events {
            switch event.type {
            case .pause:
                activeDuration += event.date.timeIntervalSince(lastResume)
            case .resume:
                lastResume = event.date
            }
        }
        
        return .seconds(activeDuration)
    }
    
    var pauseDuration: Duration {
        var pauseDuration: TimeInterval = 0
        var lastPause: Date?

        for event in events {
            switch event.type {
            case .pause:
                lastPause = event.date
            case .resume:
                pauseDuration += event.date.timeIntervalSince(lastPause!)
            }
        }
        pauseDuration += end.timeIntervalSince(lastPause!)
        
        return .seconds(pauseDuration)
    }
    
    var activeSamples: [Sample] {
        var activeSamples: [Sample] = []
        var lastResume = start

        for event in events {
            switch event.type {
            case .pause:
                let range = lastResume...event.date
                activeSamples.append(contentsOf: samples.filter { range.contains($0.date) })
            case .resume:
                lastResume = event.date
            }
        }
        
        return activeSamples
    }
    
    init(
        activity: Activity,
        start: Date,
        end: Date,
        samples: [Sample],
        events: [Event]
    ) {
        self.id = UUID()
        self.activity = activity
        self.start = start
        self.end = end
        self.samples = samples
        self.events = events
    }
    
    var averageHeartRate: Int {
        activeSamples.filter { $0.metric == .heartRate }.map(\.value).average
    }
    
    var averagePower: Int {
        activeSamples.filter { $0.metric == .power }.map(\.value).average
    }
    
}

extension Workout: Equatable {}
extension Workout: Codable {}
extension Workout: Hashable {}

extension Workout {
    
    func printDescription() {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .long
        
        print("Workout started: \(formatter.string(from: start))")
        
        for event in events {
            switch event.type {
            case .pause:
                print("Workout paused: \(formatter.string(from: event.date))")
            case .resume:
                print("Workout resumed: \(formatter.string(from: event.date))")
            }
        }
        
        print("Workout ended: \(formatter.string(from: end))")
        
        print("Total duration: \(totalDuration.formatted())")
        print("Active duration: \(activeDuration.formatted())")
        print("Pause duration: \(pauseDuration.formatted())")
    }
    
}

// MARK: - Metric

extension Workout {
    
    enum Metric: Equatable, Codable, Hashable {
        case heartRate
        case power
    }
    
}

extension Workout.Metric {
    
    var title: String {
        switch self {
        case .heartRate:
            return "Heart Rate"
        case .power:
            return "Power"
        }
    }
    
    func description(_ value: Int) -> String {
        switch self {
        case .heartRate:
            return "\(value) bpm"
        case .power:
            return "\(value) watts"
        }
    }
    
}
