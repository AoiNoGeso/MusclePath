import SwiftUI

@main
struct MusclePathApp: App {
    var body: some Scene {
        WindowGroup {
            let mockTraining = Training(
                id: 2002,
                title: "プランク",
                category: ["腹", "背中"]
            )
            
            WorkoutView(
                training: mockTraining,
                timerDuration: 5.0,
                currentXP: 1000,
                earnedXP: 50
            )
        }
    }
}
