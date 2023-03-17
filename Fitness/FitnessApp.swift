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

struct Workout: Identifiable {
    
    let id: UUID
    let activity: Activity
    let start: Date
    let end: Date
    
    var duration: Duration {
        let seconds = end.timeIntervalSince(start)
        return .seconds(seconds)
    }
    
    init(activity: Activity, start: Date, end: Date) {
        self.id = UUID()
        self.activity = activity
        self.start = start
        self.end = end
    }
    
}

extension Workout: Equatable {}
extension Workout: Codable {}

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
    static let defaultValue: Binding<[Workout]> = .constant([])
}

extension EnvironmentValues {
    
    var workouts: Binding<[Workout]> {
        get { self[WorkoutsKey.self] }
        set { self[WorkoutsKey.self] = newValue }
    }

}

extension View {
    func workouts(_ workouts: Binding<[Workout]>) -> some View {
        environment(\.workouts, workouts)
    }
}

@main
struct FitnessApp: App {
    
    var body: some Scene {
        WindowGroup {
            MainView()
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
    
    let activities: [Activity] = Activity.allCases
    
    @State private var workouts: [Workout] = []
    @Environment(\.workoutStore) private var workoutStore
    
    var body: some View {
        TabView {
            NavigationStack {
                WorkoutHistoryView()
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            
            NavigationStack {
                ActivityListView(activities: activities)
            }
            .tabItem {
                Label("New Workout", systemImage: "plus")
            }
        }
        .workouts($workouts)
        .onAppear {
            do {
                workouts = try workoutStore.get()
            } catch {
                print("Failed to load workouts -- \(error)")
            }
        }
        .onChange(of: workouts) { newValue in
            do {
                try workoutStore.save(newValue)
            } catch {
                print("Failed to save workouts -- \(error)")
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
