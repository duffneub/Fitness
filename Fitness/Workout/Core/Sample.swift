//
//  Sample.swift
//  Fitness
//
//  Created by Duff Neubauer on 4/3/23.
//

import Foundation

struct Sample: Equatable, Codable, Hashable {
    let date: Date
    let metric: Workout.Metric
    let value: Int
    
    init(metric: Workout.Metric, value: Int) {
        self.date = Date()
        self.metric = metric
        self.value = value
    }
}

extension Sample: CustomStringConvertible {
    
    var description: String {
        metric.description(value)
    }
    
}
