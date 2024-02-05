//
//  ChatService.swift
//  AI Chat Bot
//
//  Created by Sagar on 04/02/24.
//

import Foundation
import GoogleGenerativeAI

enum ChatRole {
    case user
    case model
}

struct ChatMessage: Identifiable {
    let id = UUID().uuidString
    var role: ChatRole
    var messgae: String
}

class ChatService {
    private var chat: Chat?
    var messages = [ChatMessage]()
    let model = GenerativeModel(name: "gemini-pro", apiKey: "AIzaSyCMRaH7pJV0r5PbH6yGmNn0HgWNK2_2f4Q")
    var processState: UserState = .stageOne
    
    func sendMessage(_ message: String,chatRole:ChatRole,completion: @escaping () -> Void) {
        
        if (chat == nil) {
            let history: [ModelContent] = messages.map { ModelContent(role: $0.role == .user ? "user" : "model", parts: $0.messgae)}
            chat = GenerativeModel(name: "gemini-pro", apiKey: "AIzaSyCMRaH7pJV0r5PbH6yGmNn0HgWNK2_2f4Q").startChat(history: history)
        }
        
        // MARK: Add user's message to the list
//        messages.append(.init(role: .user, messgae: message))
        Task {
               do {
                   let prompt = """
 you are an AI travel assistant and whatever user enter give response in short and precise but user interactive and say how can i assist u to plan a trip and use emojy, and from the user input u have to extract To locaton place name and from location name and duration u have to ask user for this detail till he enter and extract this detail but dont ask unnessary detail just this much and give me one by one once you got all details don't ever try to suggested any itinerary just asked for confirmation at last \(message)
 """
                   
                   let response = try await chat?.sendMessage(prompt)
                   
                   guard let text = response?.text else {
                       messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                       return
                   }
                   
                   //***
                   
                   Task{
                       do{
                           
                          let prompt = "i want to get only to, from and Duration data, to and from should be correct location name create this format To: , From:, Duration:  give the result new line if any location or duration is missing then give N/A which i given the string \(text)"
                           
                           let response = try await model.generateContent(prompt)
                           guard let text = response.text else {
                               print("Something went wrong")
                               return
                           }
                           let aiResponse = text
                           
                           DispatchQueue.main.async {
                               if let toRange = aiResponse.range(of: "To:") {
                                   // If "To:" is found, extract the substring after "To:"
                                   let startIndex = toRange.upperBound
                                   var endIndex: String.Index
                                   
                                   if let fromRange = aiResponse.range(of: "From:", range: startIndex..<aiResponse.endIndex) {
                                       // If "From:" is found after "To:", extract substring between "To:" and "From:"
                                       endIndex = fromRange.lowerBound
                                   } else {
                                       // If "From:" is not found after "To:", extract substring from "To:" to end of string
                                       endIndex = aiResponse.endIndex
                                   }
                                   
                                   TravelInfo.toLocation = aiResponse[startIndex..<endIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                               } else {
                                   // If "To:" is not found, set default value
                                   TravelInfo.toLocation = TravelInfo.toLocation
                               }
                               
                               if let fromRange = aiResponse.range(of: "From:") {
                                   let startIndex = fromRange.upperBound
                                   var endIndex: String.Index
                                   
                                   if let durationRange = aiResponse.range(of: "Duration:", range: startIndex..<aiResponse.endIndex) {
                                       // If "Duration:" is found after "From:", extract substring between "From:" and "Duration:"
                                       endIndex = durationRange.lowerBound
                                   } else {
                                       // If "Duration:" is not found after "From:", extract substring from "From:" to end of string
                                       endIndex = aiResponse.endIndex
                                   }
                                   
                                   TravelInfo.fromLocation = aiResponse[startIndex..<endIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                               } else {
                                   // If "From:" is not found, set default value
                                   TravelInfo.fromLocation = TravelInfo.fromLocation
                               }
                               
                               
                               if let durationRange = aiResponse.range(of: "Duration:") {
                                   // If "Duration:" is found, extract the substring after "Duration:"
                                   let startIndex = durationRange.upperBound
                                   var endIndex: String.Index
                                   
                                   if let dateRange = aiResponse.range(of: "Date:", range: startIndex..<aiResponse.endIndex) {
                                       // If "Date:" is found after "Duration:", extract substring between "Duration:" and "Date:"
                                       endIndex = dateRange.lowerBound
                                   } else {
                                       // If "Date:" is not found after "Duration:", extract substring from "Duration:" to end of string
                                       endIndex = aiResponse.endIndex
                                   }
                                   
                                   TravelInfo.duration = aiResponse[startIndex..<endIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                               } else {
                                   // If "Duration:" is not found, set default value
                                   TravelInfo.duration = TravelInfo.duration
                               }
                               
                               if let dateRange = aiResponse.range(of: "Date:") {
                                   // If "Date:" is found, extract the substring after "Date:"
                                   let startIndex = dateRange.upperBound
                                   let endIndex = aiResponse.endIndex
                                   
                                   TravelInfo.date = aiResponse[startIndex..<endIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                               } else {
                                   // If "Date:" is not found, set default value
                                   TravelInfo.date = TravelInfo.date
                               }
                               
                               print("To:", TravelInfo.toLocation ?? "N/A")
                               print("From:", TravelInfo.fromLocation ?? "N/A")
                               print("Duration:", TravelInfo.duration ?? "N/A")
                               print("Date:", TravelInfo.date ?? "N/A")
               
                           }
                               
                           } catch {
//                               self.activityIndicator.stopAnimating()
                               print(error.localizedDescription)
                           }
                       }

                
                   //***
                   
                   print(text)
                   if chatRole == .user {
                       messages.append(.init(role: .user, messgae: text))
                   }else {
                       messages.append(.init(role: .model, messgae: text))
                   }
                   
                   completion() // Call completion after appending message
               }
               catch {
                   messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                   completion() // Call completion after appending error message
               }
           }
    }
    
    
    
    //MARK: - For the first time
    func startingSendMessage(_ message: String,chatRole:ChatRole,completion: @escaping () -> Void) {
        
        if (chat == nil) {
            let history: [ModelContent] = messages.map { ModelContent(role: $0.role == .user ? "user" : "model", parts: $0.messgae)}
            chat = GenerativeModel(name: "gemini-pro", apiKey: "AIzaSyCMRaH7pJV0r5PbH6yGmNn0HgWNK2_2f4Q").startChat(history: history)
        }
        
        
        Task {
               do {
                   let prompt = ""
                   let response = try await chat?.sendMessage(prompt)
                   
                   guard let text = response?.text else {
                       messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                       return
                   }
                 
//                   print(text)
//                   if chatRole == .user {
//                       messages.append(.init(role: .user, messgae: text))
//                   }else {
//                       messages.append(.init(role: .model, messgae: text))
//                   }
                   
                   completion() // Call completion after appending message
               }
               catch {
                   messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                   completion() // Call completion after appending error message
               }
           }
    }
    
    func stageFirstConfirm(_ message: String,chatRole:ChatRole,completion: @escaping () -> Void) {
        
        if (chat == nil) {
            let history: [ModelContent] = messages.map { ModelContent(role: $0.role == .user ? "user" : "model", parts: $0.messgae)}
            chat = GenerativeModel(name: "gemini-pro", apiKey: "AIzaSyCMRaH7pJV0r5PbH6yGmNn0HgWNK2_2f4Q").startChat(history: history)
        }
        
        // MARK: Add user's message to the list
//        messages.append(.init(role: .user, messgae: message))
        Task {
               do {
                   let prompt = """
                    form the user input your need to check if he say yes then give output happy to help you could u please suggest me your interest or else if he say no i want to change or anything like changing details then give output sure what you want to change but if he say yes don't say anything about changing anydetails since he confirm already
                    """
                   

                   let response = try await chat?.sendMessage(prompt)
                   
                   guard let text = response?.text else {
                       messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                       return
                   }
                   
                   //***
                   
//                   Task{
//                       do{
//                           
//                          let prompt = " You need to understand user text and if he say yes i like or yes then formate it in YES:1 and if he say no i want to chnage then or just he say no then formate it in NO:0\(message)"
//                           
//                           let response = try await model.generateContent(prompt)
//                           guard let text = response.text else {
//                               print("Something went wrong")
//                               return
//                           }
//                           let aiResponse = text
//                           
//                           DispatchQueue.main.async {
//                              
//                               print("To:", TravelInfo.toLocation ?? "N/A")
//                               print("From:", TravelInfo.fromLocation ?? "N/A")
//                               print("Duration:", TravelInfo.duration ?? "N/A")
//                               print("Date:", TravelInfo.date ?? "N/A")
//                               
//                               TravelInfo.confirmDetails = aiResponse
//                               print(TravelInfo.confirmDetails)
//                               
//                               if (TravelInfo.confirmDetails == "YES:1") || (TravelInfo.confirmDetails == "YES: 1") {
//                                   self.processState = .stageTwo
//                               }else {
//                                   self.processState = .stageOne
//                               }
//                               
//                           }
//                               
//                           } catch {
////                               self.activityIndicator.stopAnimating()
//                               print(error.localizedDescription)
//                           }
//                       }

                   var extractedText = ""

                   if message.lowercased().contains("yes") {
                       extractedText = "Yes"
                   } else if message.lowercased().contains("no") {
                       extractedText = "No"
                   }

                   let formattedResult = "\(extractedText)"
                   if formattedResult == "Yes" {
                       self.processState = .stageTwo
                   }else {
                       self.processState = .stageOne
                   }
                   print(formattedResult)
                   
                   print(text)
                   if chatRole == .user {
                       messages.append(.init(role: .user, messgae: text))
                   }else {
                       messages.append(.init(role: .model, messgae: text))
                   }
                   
                   completion() // Call completion after appending message
               }
               catch {
                   messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                   completion() // Call completion after appending error message
               }
           }
    }
}


//
