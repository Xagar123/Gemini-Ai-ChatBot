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
                let prompt = "You are expert in understanding user sentiment,You need to extract preference in terms of budget:something like budget-friendly, comfortable, or luxurious from this text \(String(describing: message)) and give response in single line in beautiful way but don't ask confirmation and if there is nothing like budget then u need to asked for budget type"
                let response = try await chat?.sendMessage(prompt)
                
                guard let convertText = response?.text else {
                    messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                    return
                }
                //MARK: - extracting budget type
                Task {
                    do {
                        
                        let prompt = """
                            Checks if the text \(String(describing: message)) contains keywords related or equivalent to budget-friendly, comfortable, or luxurious then give Output:1 if any related keywords are found,Output:0 length max 0 - 5 letters.
                                  
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
                                                TravelInfo.budgetPreference = "budget-friendly"
                                                TravelInfo.isBudgetPreferenceExtracted = true
                                                messages.append(.init(role: .model, messgae: "Noted! It seems you're looking for a budget-friendly trip. 💰 I'll keep that in mind while planning your itinerary."))
                                                self.getActivityAndInterest {
                                                    self.reloadTableViewClosure?()
                                                }
                                            case 2:
                                                TravelInfo.budgetPreference = "comfortable"
                                                TravelInfo.isBudgetPreferenceExtracted = true
                                                messages.append(.init(role: .model, messgae: "Noted! It seems you're looking for a comfortable trip. 💰 I'll keep that in mind while planning your itinerary."))
                                                self.getActivityAndInterest {
                                                    self.reloadTableViewClosure?()
                                                }
                                            case 3:
                                                TravelInfo.budgetPreference = "luxurious"
                                                TravelInfo.isBudgetPreferenceExtracted = true
                                                messages.append(.init(role: .model, messgae: "Noted! It seems you're looking for a luxurious trip. 💰 I'll keep that in mind while planning your itinerary."))
                                                self.getActivityAndInterest {
                                                    self.reloadTableViewClosure?()
                                                }
                                            default:
                                                TravelInfo.budgetPreference = "unknown"
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
                        messages.append(.init(role: .model, messgae: "\(convertText) please select any of this budget-friendly, comfortable, or luxurious "))
                        
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
                    let prompt = "i want to go to \(String(describing: TravelInfo.toLocation)), you need to suggest me what all interest/activity available in the \(String(describing: TravelInfo.toLocation)) and give only 6 best interest/activity only tittle name length max 0 - 5 letters."
                    let response = try await model.generateContent(prompt)
                    
                    guard let text = response.text else {
                        messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                        return
                    }
                    
                    print(text)
                    let dataArray = text.components(separatedBy: "\n")
                    TravelInfo.destInterest = dataArray
                    let selectedButtons = [dataArray[0], dataArray[2], dataArray[4]]
                    let selectedOptions = selectedButtons.joined(separator: ", ")
                    TravelInfo.selectedInterest = selectedOptions
                    
                    print(selectedOptions)
                    print(dataArray)
                    messages.append(.init(role: .model, messgae: text))
                    
                    // custome message
                    messages.append(.init(role: .model, messgae: "Generating itineary for you"))
                    self.isUpdate = true
                    self.processState = .stageThree
                    completion()
                    
                    
                }
                catch {
                    messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                }
            }
        }
        
        
    }
    
}
