//
//  FitnessApp.swift
//  Fitness
//
//  Created by Duff Neubauer on 3/7/23.
//

import SwiftUI

enum Activity: Identifiable, Codable, CaseIterable {
    
    case indoorRide
    case indoorRun
    case outdoorRide
    case outdoorRun
    
    var id: Self { self }
    
    var name: String {
        switch self {
        case .indoorRide:
            return "Indoor Ride"
        case .indoorRun:
            return "Indoor Run"
        case .outdoorRide:
            return "Outdoor Ride"
        case .outdoorRun:
            return "Outdoor Run"
        }
    }
    
    
    var image: String {
        switch self {
        case .indoorRide:
            return "figure.indoor.cycle"
        case .indoorRun:
            return "figure.run"
        case .outdoorRide:
            return "figure.outdoor.cycle"
        case .outdoorRun:
            return "figure.run"
        }
    }
}

// MARK: - Environment

private struct WorkoutStoreKey: EnvironmentKey {
    static let defaultValue: Store<Workout> = .unimplemented
}

extension EnvironmentValues {
    
    var workoutStore: Store<Workout> {
        get { self[WorkoutStoreKey.self] }
        set { self[WorkoutStoreKey.self] = newValue }
    }

}

private struct WorkoutsKey: EnvironmentKey {
    static let defaultValue: [Workout] = []
}

extension EnvironmentValues {
    
    var workouts: [Workout] {
        get { self[WorkoutsKey.self] }
        set { self[WorkoutsKey.self] = newValue }
    }

}

extension View {
    func workouts(_ workouts: [Workout]) -> some View {
        environment(\.workouts, workouts)
    }
}

private struct AddWorkoutKey: EnvironmentKey {
    static let defaultValue: AddWorkoutAction = .init(action: { _ in fatalError("Unimplemented") })
}

extension EnvironmentValues {
    
    var addWorkout: AddWorkoutAction {
        get { self[AddWorkoutKey.self] }
        set { self[AddWorkoutKey.self] = newValue }
    }

}

struct AddWorkoutAction {
    
    let action: (Workout) -> Void
    
    func callAsFunction(_ workout: Workout) {
        action(workout)
    }
    
}

extension View {
    
    func onAddWorkout(_ addWorkout: @escaping (Workout) -> Void) -> some View {
        environment(\.addWorkout, .init(action: addWorkout))
    }
    
}

class Model: ObservableObject {
    
    @Published private(set) var profiles: [WorkoutProfile]
    
    // Should this be an ID?
    @Published var currentProfile: WorkoutProfile?
    
    init() {
        profiles = [
           .init(activity: .indoorRide),
           .init(activity: .indoorRun),
           .init(activity: .outdoorRide),
           .init(activity: .outdoorRun),
       ]
    }
    
}

@main
struct FitnessApp: App {
    
    @StateObject private var model = Model()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(model)
                .environment(\.workoutStore, .fileSystem(workoutsLocation))
        }
    }
    
    private func workoutsLocation() throws -> URL {
        try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        .appendingPathComponent("fitness.data", conformingTo: .data)
    }

}

struct MainView: View {
    
    enum Tab: Hashable {
        case workoutHistory
        case newWorkout
        case foo
    }
    
    let activities: [Activity] = Activity.allCases
    
    @State private var workouts: [Workout] = []
    @Environment(\.workoutStore) private var workoutStore
    let bluetoothStore = BluetoothStore()
    
    @State private var tab: Tab = .workoutHistory
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        TabView(selection: $tab) {
            NavigationStack(path: $navigationPath) {
                WorkoutHistoryView()
                    .workouts(workouts)
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            .tag(Tab.workoutHistory)
            
            NavigationStack {
                WorkoutProfilesViewOld(bluetoothStore: bluetoothStore)
                    .onAddWorkout { workout in
                        workouts.append(workout)
                        
                        tab = .workoutHistory
                        navigationPath = .init()
                        navigationPath.append(workout)
                        
                        do {
                            try workoutStore.save(workouts)
                        } catch {
                            print("Failed to save workouts -- \(error)")
                        }
                    }
//                    .sensorStore(.bluetooth)
            }
            .tabItem {
                Label("New Workout", systemImage: "plus")
            }
            .tag(Tab.newWorkout)
        }
        .onAppear {
            do {
                workouts = try workoutStore.get()
            } catch {
                print("Failed to load workouts -- \(error)")
            }
        }
    }
    
}

struct Store<T: Codable> {
    
    let get: () throws -> [T]
    let save: ([T]) throws -> Void
    
}

extension Store<Workout> {
    
    static let unimplemented = Self.init(
        get: { fatalError("Store.get is unimplemented") },
        save: { _ in fatalError("Store.set is unimplemented") }
    )
    
}

extension Store {
    
    static func fileSystem(_ location: @escaping () throws -> URL) -> Self {
        .init(
            get: {
                let location = try location()
                guard FileManager.default.fileExists(atPath: location.path()) else {
                    return []
                }
                let file = try FileHandle(forReadingFrom: location)
                return try JSONDecoder().decode([T].self, from: file.availableData)
            },
            save: { items in
                let data = try JSONEncoder().encode(items)
                try data.write(to: try location())
            }
        )
    }
    
}
