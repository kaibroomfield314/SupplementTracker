import Foundation
import SwiftUI

enum UserPreferenceKeys {
    static let userName = "userPref.userName"
    static let avatarData = "userPref.avatarData"
    static let goalName = "userPref.goalName"
    static let goalStart = "userPref.goalStart"
    static let goalDays = "userPref.goalDays"
    static let lastCelebratedStreak = "userPref.lastCelebratedStreak"
    static let undoArmedID = "userPref.undoArmedID"
    static let notificationsEnabled = "userPref.notificationsEnabled"
}

struct GoalInfo: Equatable {
    var name: String
    var startDate: Date
    var totalDays: Int

    var elapsedDays: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: .now).day ?? 0
        return max(1, days + 1)
    }

    var progress: Double {
        guard totalDays > 0 else { return 0 }
        return min(1.0, Double(elapsedDays) / Double(totalDays))
    }
}
