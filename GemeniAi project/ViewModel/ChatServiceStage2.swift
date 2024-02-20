//
//  ChatServiceStage2.swift
//  GemeniAi project
//
//  Created by Sagar on 13/02/24.
//

import Foundation

extension ChatService {
    
    
    //MARK: - Stage 2
    func getBudgetType(_ message: String?, completion: @escaping() -> Void) {
        Task {
            do {
                let prompt = "You are expert in understanding user sentiment,You need to extract preference in terms of budget:something like budget-friendly, comfortable, or luxurious from this text \(String(describing: messages)) and give response in single line in beautiful way but don't ask confirmation and if there is nothing like budget then u need to asked for budget type"
                let response = try await chat?.sendMessage(prompt)
                
                guard let convertText = response?.text else {
                    messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                    return
                }
                //MARK: - extracting budget type
                Task {
                    do {
                        
                        let prompt = """
                            Checks if the text \(String(describing: convertText)) contains keywords related or equivalent to budget-friendly, comfortable, or luxurious then give Output:1 if any related keywords are found,Output:0 length max 0 - 5 letters.
                                  
                            """
                        let response = try await model.generateContent(prompt)
                        
                        guard let text = response.text else {
                            messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                            return
                        }
                        if let extractNum = extractNumber(from: text) {
                            switch extractNum {
                            case 0:
                                print(text)
                                //                                messages.append(.init(role: .model, messgae: "please select any of this budget-friendly, comfortable, or luxurious "))
                            case 1:
                                Task{
                                    do {
                                        let prompt = "You are expert in extracting data from text,You need to extract preference in terms of budget: for budget-friendly give 1 , for comfortable give 2, and for luxurious give 3,extract data from this text \(String(describing: message)) \(convertText)"
                                        let response = try await chat?.sendMessage(prompt)
                                        
                                        guard let text = response?.text else {
                                            messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                                            return
                                        }
                                        
                                        if let number = extractNumber(from: text) {
                                            switch number {
                                            case 1:
                                                TravelInfo.shared.budgetPreference = "budget-friendly"
                                                self.stageSecondProcessState = .isInterestSelected
                                                TravelInfo.shared.isBudgetPreferenceExtracted = true
                                                messages.append(.init(role: .model, messgae: "Noted! It seems you're looking for a budget-friendly trip. 💰 I'll keep that in mind while planning your itinerary."))
                                                self.getActivityAndInterest {
                                                    self.reloadTableViewClosure?()
                                                }
                                            case 2:
                                                TravelInfo.shared.budgetPreference = "comfortable"
                                                self.stageSecondProcessState = .isInterestSelected
                                                messages.append(.init(role: .model, messgae: "Noted! It seems you're looking for a comfortable trip. 💰 I'll keep that in mind while planning your itinerary."))
                                                self.getActivityAndInterest {
                                                    self.reloadTableViewClosure?()
                                                }
                                            case 3:
                                                TravelInfo.shared.budgetPreference = "luxurious"
                                                self.stageSecondProcessState = .isInterestSelected
                                                messages.append(.init(role: .model, messgae: "Noted! It seems you're looking for a luxurious trip. 💰 I'll keep that in mind while planning your itinerary."))
                                                self.getActivityAndInterest {
                                                    self.reloadTableViewClosure?()
                                                }
                                            default:
                                                TravelInfo.shared.budgetPreference = "unknown"
                                            }
                                        }else {
                                            print(text)
                                            messages.append(.init(role: .model, messgae: text))
                                        }
                                        
                                        //                                        messages.append(.init(role: .model, messgae: text))
                                        completion()
                                    } catch {
                                        messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                                    }
                                }
                                
                            default:
                                print(text)
                                //                                messages.append(.init(role: .model, messgae: "please select any of this budget-friendly, comfortable, or luxurious"))
                            }
                        }
                        
                        
                        print(convertText)
                        messages.append(.init(role: .model, messgae: "\(convertText)  "))
                        
                        completion()
                    } catch {
                        messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                    }
                }
            }
        }
    }
    
    func extractNumber(from text: String) -> Int? {
        let pattern = #"(\d+)"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        if let match = matches.first {
            let range = match.range(at: 1)
            if let swiftRange = Range(range, in: text) {
                let numberText = text[swiftRange]
                if let number = Int(numberText) {
                    return number
                }
            }
        }
        
        return nil
    }
    
    
    //MARK: - Activity/Interest
    func getActivityAndInterest(_ completion:@escaping() -> Void) {
        /*
         Suggesting interest and activity user can perform at that perticular locatio
         */
        //
        Task {
            let textMessage = "Let our AI know what kind of things you’d like to do on your trip!"
            messages.append(.init(role: .model, messgae:textMessage))
            self.reloadTableViewClosure?()
            Task {
                do {
                    let prompt = "i want to go to \(String(describing: TravelInfo.shared.toLocation)), you need to suggest me what all interest/activity available in the \(String(describing: TravelInfo.shared.toLocation)) and give only 6 best interest/activity only tittle name length max 0 - 5 letters."
                    let response = try await model.generateContent(prompt)
                    
                    guard let text = response.text else {
                        messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                        return
                    }
                    
                    print(text)
                    let dataArray = text.components(separatedBy: "\n")
                    TravelInfo.shared.destInterest = dataArray
                    let selectedButtons = [dataArray[0], dataArray[2], dataArray[4]]
                    let selectedOptions = selectedButtons.joined(separator: ", ")
                    TravelInfo.shared.selectedInterest = selectedOptions
                    
                    print(selectedOptions)
                    print(dataArray)
                    messages.append(.init(role: .model, messgae: text + "Please select interset"))
                    
                    // custome message
                    let foodPreference = """
                    To help us cater to your taste buds, tell us about your food preferences:
                    1. Vegetarian 🥬
                    2. Non-Vedge 🍗
                    3. Vegan 🍏
                    """
                    messages.append(.init(role: .model, messgae: foodPreference))
                    self.isUpdate = true
//                    self.processState = .stageThree
                    self.stageSecondProcessState = .isFoodPreferenceSelected
                    completion()
                    
                    
                }
                catch {
                    messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                }
            }
        }
      
    }
    
    //MARK: - Food preference
    
    func getFoodPreferenceType(_ userInput: String , completion: @escaping() -> Void) {
        Task {
            do {
                let prompt = """
                             from the given text \(userInput) you need to extract food preferences type: in form of
                                1.Vegetarian
                                2.Non-Vedge
                                3.Vegan
                                if any of this there then return type = {result}
                                example: i will prefer non-veg
                                output: type = Non-Vedge
                                don't give unnecessary give output single one word such as Vegetarian or Non-Vedge or Vegan
                              details if its doesn't contain then retun type ={N/A}
                            """
                let response = try await chat?.sendMessage(prompt)
                guard let text = response?.text else {
                    messages.append(.init(role: .model, messgae: "Something went wrong"))
                    return
                }
                
                if let foodType = extractFoodType(input: text) {
                    print(foodType)
                    
                    if (foodType == "Vegetarian") || (foodType == "Vegetarian ")  {
                        print("Vege")
                        let foodPref = "That's good to know you're vegetarian"
                        TravelInfo.shared.foodPreference = foodPref
                        messages.append(.init(role: .model, messgae: foodPref))
                        completion()
                    } else if (foodType == "Non-Vedge") || (foodType == "Non-Vedge ") {
                        print("non-veg")
                        let foodPref = "That's good to know you're Non-Vedge"
                        TravelInfo.shared.foodPreference = foodPref
                        messages.append(.init(role: .model, messgae: foodPref))
                        completion()
                    } else if (foodType == "Vegan") || foodType == "Vegan " {
                        print("vegan")
                        let foodPref = "That's good to know you're Vegan"
                        TravelInfo.shared.foodPreference = foodPref
                        messages.append(.init(role: .model, messgae: foodPref))
                        completion()
                    } else if foodType == "N/A" {
                        Task {
                            let prompt = """
                            \(userInput) suggest me best food preference for this place \(String(describing: TravelInfo.shared.toLocation)) give output in 20 words
                            """
                            let response = try await chat?.sendMessage(prompt)
                            guard let convertedText = response?.text else {
                                return
                            }
                            print(convertedText)
                            messages.append(.init(role: .model, messgae: convertedText + "which food you will prefer"))
                            completion()
                        }
                    }
                }else {
                    Task {
                        let prompt = """
                        \(userInput) suggest me best food preference for this place \(String(describing: TravelInfo.shared.toLocation)) and tell him to enter food type 1.Vegetarian
                                2.Non-Vedge
                                3.Vegan give output in 20 words
                        """
                        let response = try await chat?.sendMessage(prompt)
                        guard let convertedText = response?.text else {
                            return
                        }
                        print(convertedText)
                        messages.append(.init(role: .model, messgae: convertedText))
                        completion()
                    }
                }
               
                completion()
                
         
            } catch {
                messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
            }
        }
    }
    
    //Extracting the foodtype
    func extractFoodType(input: String) -> String? {
        let pattern = "Type: (.+)"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            if let match = regex.firstMatch(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count)) {
                if let range = Range(match.range(at: 1), in: input) {
                    var type = String(input[range]) // Convert Substring to String
                    // Remove emoji
                    type = type.replacingOccurrences(of: "\\p{Emoji}", with: "", options: .regularExpression)
                    return type
                }
            }
        } catch {
            print("Error: \(error)")
        }
        return nil
    }

    
}
