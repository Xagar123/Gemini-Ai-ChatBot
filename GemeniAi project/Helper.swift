//
//  Helper.swift
//  GemeniAi project
//
//  Created by Sagar on 02/02/24.
//

import Foundation

struct TravelInfo {
    static var toLocation: String? = "N/A"
    static var fromLocation: String? = "N/A"
    static var duration: String? = "N/A"
    static var date: String? = "N/A"
    static var confirmDetails: String? = "N/A"
    
    static var newUser:Bool = true
    static var existingUser:Bool = false
    
    static var destInterest = [String]()
    static var selectedInterest:String?
    
    
    //MARK: - Stage 2 details
    static var budgetPreference: String? = ""
    static var isBudgetPreferenceExtracted:Bool = false
}

enum UserState {
    case stageOne
    case stageTwo
    case stageThree
}

