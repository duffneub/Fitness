//
//  WorkoutProfile.swift
//  Fitness
//
//  Created by Duff Neubauer on 4/9/23.
//

import Foundation

struct WorkoutProfile: Identifiable {
    
    typealias ID = UUID
    
    let id = ID()
    let activity: Activity
    let sensors: [Sensor.ID] = []
    
    var name: String { activity.name }
    var image: String { activity.image }
}

extension WorkoutProfile: Equatable {}
