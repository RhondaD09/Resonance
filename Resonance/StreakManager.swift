//
//  StreakManager.swift
//  Resonance
//
//  Created by Alexus WIlliams on 5/1/26.
//

import Foundation
import SwiftUI
import UIKit

// Note: This is a non-View

final class StreakManager {
    
    static let shared = StreakManager()
    
    private let streakKey = "streakCount"
    private let lastLoginKey = "lastLoginDate"
    
    var streakCount: Int {
        UserDefaults.standard.integer(forKey: streakKey)
    }
    
    func updateStreak() {
        let now = Date()
        let calendar = Calendar.current
        
        if let lastLogin = UserDefaults.standard.object(forKey: lastLoginKey) as? Date {
            
            let hours = calendar.dateComponents([.hour], from: lastLogin, to: now).hour ?? 0
            
            if hours <= 24 {
                // Continue streak
                if !calendar.isDate(lastLogin, inSameDayAs: now) {
                    UserDefaults.standard.set(streakCount + 1, forKey: streakKey)
                }
            } else {
                // Reset streak
                UserDefaults.standard.set(1, forKey: streakKey)
            }
            
        } else {
            // First time opening app
            UserDefaults.standard.set(1, forKey: streakKey)
        }
        
        UserDefaults.standard.set(now, forKey: lastLoginKey)
    }
}
