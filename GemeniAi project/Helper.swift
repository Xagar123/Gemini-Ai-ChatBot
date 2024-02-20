//
//  Helper.swift
//  GemeniAi project
//
//  Created by Sagar on 02/02/24.
//

import Foundation

class TravelInfo {
    static let shared = TravelInfo()
    
    private init() {} // Private initializer to prevent external instantiation
    
    var toLocation: String? = "N/A"
    var fromLocation: String? = "N/A"
    var duration: String? = "N/A"
    var date: String? = "N/A"
    var confirmDetails: String? = "N/A"
    
    var destInterest = [String]()
    var selectedInterest: String?
    
    //MARK: - Stage 2 details
    var budgetPreference: String? = ""
    var isBudgetPreferenceExtracted: Bool = false
    
    // for food preference
    var foodPreference: String = ""
    var isFoodPreferenceSelected: Bool = false
    
    
}

enum UserState {
    case stageOne
    case stageTwo
    case stageThree
}


enum StageSecondUserState {
    case isBudgetPreferenceSelected
    case isInterestSelected
    case isFoodPreferenceSelected
}
