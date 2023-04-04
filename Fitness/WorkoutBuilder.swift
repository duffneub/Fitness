//
//  WorkoutBuilder.swift
//  Fitness
//
//  Created by Duff Neubauer on 4/3/23.
//

import Foundation

class WorkoutBuilder: ObservableObject {
    
    enum Status {
        case ready
        case inProgress
        case paused
        case complete
    }
    
    let activity: Activity
    
    @Published var samples: [Sample] = []

    @Published private(set) var duration: Duration = .milliseconds(0)
    @Published private(set) var status: Status = .ready
    
    private var start: Date?
    private var accumulatedTime: Duration =  .milliseconds(0)
    private var timer: Timer?
    private var events: [Workout.Event] = []
    
    init(activity: Activity) {
        self.activity = activity
    }
    
    func startWorkout() {
        guard start == nil else { return }
        let now = Date()
        start = now
        
        timer = .scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            let seconds = Date().timeIntervalSince(now)
            self.duration = self.accumulatedTime + .seconds(seconds)
        }
        status = .inProgress
    }
    
    func pause() {
        events.append(.init(date: Date(), type: .pause))
        timer?.invalidate()
        accumulatedTime = duration
        status = .paused
    }
    
    func resume() {
        let now = Date()
        events.append(.init(date: now, type: .resume))
        
        timer = .scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            let seconds = Date().timeIntervalSince(now)
            self.duration = self.accumulatedTime + .seconds(seconds)
        }
        status = .inProgress
    }
    
    func stopWorkout() -> Workout {
        let end = Date()
        status = .complete
        
        return Workout(
            activity: activity,
            start: start ?? end,
            end: end,
            samples: samples,
            events: events
        )
    }
    
}
