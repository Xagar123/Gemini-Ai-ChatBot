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
    
    let model = GenerativeModel(name: "gemini-pro", apiKey: "AIzaSyCMRaH7pJV0r5PbH6yGmNn0HgWNK2_2f4Q", generationConfig: GenerationConfig(
        temperature: 0,
        topP: 1,
        topK: 1,
        maxOutputTokens: 2048
    ),safetySettings: [
        SafetySetting(harmCategory: .harassment, threshold: .blockMediumAndAbove),
        SafetySetting(harmCategory: .hateSpeech, threshold: .blockMediumAndAbove),
        SafetySetting(harmCategory: .sexuallyExplicit, threshold: .blockMediumAndAbove),
        SafetySetting(harmCategory: .dangerousContent, threshold: .blockMediumAndAbove)
    ] )
                                    
    var processState: UserState = .stageOne
    
    var isUpdate:Bool = false
    
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
 you are an AI travel assistant and whatever user enter give response in short and precise but user interactive and say how can i assist u to plan a trip and use emojy, and from the user input u have to extract To locaton place name and from location name and duration you have to ask user for this detail till he enter and extract this detail and from location is must but dont ask unnessary detail just this much and give me one by one once you got all details don't ever try to suggested any itinerary just asked for confirmation at last \(message)
 """
                   
                   let response = try await chat?.sendMessage(prompt)
                   
                   guard let text = response?.text else {
                       messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                       return
                   }
                   
                   //***
                   
                   Task{
                       do{
                           
                          let prompt = "i want to get only to, from and Duration data, to and from should be correct location name create this format To: , From:, Duration: and date in dd/mm/2024 give the result new line if any location or duration is missing then give N/A which i given the string \(text)"
                           
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
                               
                               if (TravelInfo.toLocation != "N/A") && (TravelInfo.fromLocation != "N/A") && (TravelInfo.duration != "N/A") {
                                   self.isUpdate = true
                               }
               
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
        
        // MARK: Check user is agree or not

        Task {
               do {
                   let prompt = """
                    You are expert in understanding user sentiments. If the user expresses satisfaction by saying "Yes, I like it," the system should respond with "Yes:1". However, if the user indicates a desire to modify details by saying "I want to change some details," the system should respond with "No:0". Handle both scenarios accordingly. If the user's response doesn't fit either case, return "N/A".

                    \(message)
                    """
                   

                   let response = try await chat?.sendMessage(prompt)
                   
                   guard let text = response?.text else {
                       messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                       return
                   }
                   
                   var yesDetailVal: String?
                   var noDetailVal: String?
                   
                   // Define regular expressions to match "Yes:1" and "No:0" patterns
                   let yesRegex = try! NSRegularExpression(pattern: "(Yes:1)", options: .caseInsensitive)
                   let noRegex = try! NSRegularExpression(pattern: "(No:0)", options: .caseInsensitive)

                   // Match "Yes:1"
                   if let yesMatch = yesRegex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {
                       let yesDetail = String(text[Range(yesMatch.range, in: text)!])
                       yesDetailVal = yesDetail
                       print("Extracted Yes Detail: \(yesDetail)")
                   } else {
                       print("No 'Yes:1' detail found")
                   }

                   // Match "No:0"
                   if let noMatch = noRegex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {
                       let noDetail = String(text[Range(noMatch.range, in: text)!])
                       print("Extracted No Detail: \(noDetail)")
                       noDetailVal = noDetail
                   } else {
                       print("No 'No:0' detail found")
                   }
                   
                   if yesDetailVal == "Yes:1" {
                       /*
                        Let's move to next stage since user confirm all his details
                        */
                       self.processState = .stageTwo
                       let textMessage = "Let our AI know what kind of things you’d like to do on your trip!"
                       messages.append(.init(role: .model, messgae: textMessage))
                       self.isUpdate = true
                       /*
                        Suggesting interest and activity user can perform at that perticular locatio
                        */
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
                   } else {
                       /*
                        Moving back to stage 1 as user want to update his details
                        */
                       self.processState = .stageOne

                       Task {
                           do {
                               let prompt = "Asked user what details he want to update"
                               let response = try await chat?.sendMessage(prompt)
                               
                               guard let text = response?.text else {
                                   messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                                   return
                               }
                               
                               print(text)
                               messages.append(.init(role: .model, messgae: text))
                               self.isUpdate = false
                               completion()
                              
                           }
                           catch {
                               messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                           }
                       }
                   }

                   completion() // Call completion after appending message
               }
               catch {
                   messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                   completion() // Call completion after appending error message
               }
           }
    }
    
    
    //MARK: - SUGGESTION FOR INTEREST
    
    func interestAndSuggestion(_ message: String?, completion: @escaping() -> Void) {
        Task {
            do {
                let prompt = "i am planning a trip form \(String(describing: TravelInfo.fromLocation)) to \(String(describing: TravelInfo.toLocation)) for \(String(describing: TravelInfo.duration)) asked for confirmation "
                let response = try await chat?.sendMessage(prompt)
                
                guard let text = response?.text else {
                    messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                    return
                }
               
                //MARK: - IF NEED TO CHANGE ANY PREVIOUS DETAIL
                Task {
                       do {
                           let prompt = """
                            You're designing a response system based on user input. If the user expresses satisfaction by saying "Yes, I like it," the system should respond with "Yes:1". However, if the user indicates a desire to modify details by saying "I want to change some details," the system should respond with "No:0". Handle both scenarios accordingly. If the user's response doesn't fit either case, return "N/A".

                            \(String(describing: message))
                            """
                           

                           let response = try await chat?.sendMessage(prompt)
                           
                           guard let text = response?.text else {
                               messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                               return
                           }
                           
                           var yesDetailVal: String?
                           var noDetailVal: String?
                           
                           // Define regular expressions to match "Yes:1" and "No:0" patterns
                           let yesRegex = try! NSRegularExpression(pattern: "(Yes:1)", options: .caseInsensitive)
                           let noRegex = try! NSRegularExpression(pattern: "(No:0)", options: .caseInsensitive)

                           // Match "Yes:1"
                           if let yesMatch = yesRegex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {
                               let yesDetail = String(text[Range(yesMatch.range, in: text)!])
                               yesDetailVal = yesDetail
                               print("Extracted Yes Detail: \(yesDetail)")
                           } else {
                               print("No 'Yes:1' detail found")
                           }

                           // Match "No:0"
                           if let noMatch = noRegex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {
                               let noDetail = String(text[Range(noMatch.range, in: text)!])
                               print("Extracted No Detail: \(noDetail)")
                               noDetailVal = noDetail
                           } else {
                               print("No 'No:0' detail found")
                           }
                           
                           if yesDetailVal == "Yes:1" {
                               /*
                                Let's move to next stage since user confirm all his details
                                */
//                               self.processState = .stageTwo
//                               let textMessage = "Let our AI know what kind of things you’d like to do on your trip!"
//                               messages.append(.init(role: .model, messgae: textMessage))
//                               self.isUpdate = false
//                               /*
//                                Suggesting interest and activity user can perform at that perticular locatio
//                                */
//                               Task {
//                                   do {
//                                       let prompt = "You are expert at suggesting interest, my user is planning a trip to \(String(describing: TravelInfo.toLocation)) location you have to suggest  all activity he can do in that place step by step in point \(messages) u have to asked for user input and confirmation "
//                                       let response = try await chat?.sendMessage(prompt)
//                                       
//                                       guard let text = response?.text else {
//                                           messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
//                                           return
//                                       }
//                                       
//                                       print(text)
//                                       messages.append(.init(role: .model, messgae: text))
//                                       self.isUpdate = false
//                                       completion()
//                                       
//                                      
//                                   }
//                                   catch {
//                                       messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
//                                   }
//                               }
                           } else {
                               /*
                                Moving back to stage 1 as user want to update his details
                                */
                               self.processState = .stageOne

                               Task {
                                   do {
                                       let prompt = "Previously we a planned my trip from \(String(describing: TravelInfo.fromLocation)) to \(String(describing: TravelInfo.toLocation)) for \(String(describing: TravelInfo.duration)) days and \(String(describing: TravelInfo.date)) date.Now Asked user what details he want to update and update only that perticular data and rest will be same"
                                       let response = try await chat?.sendMessage(prompt)
                                       
                                       guard let text = response?.text else {
                                           messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                                           return
                                       }
                                       
                                       print(text)
                                       messages.append(.init(role: .model, messgae: text))
                                       self.isUpdate = true
                                       completion()
                                       
                                      
                                   }
                                   catch {
                                       messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                                   }
                               }
                           }

                           completion() // Call completion after appending message
                       }
                       catch {
                           messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                           completion() // Call completion after appending error message
                       }
                   }
                
                print(text)
                messages.append(.init(role: .model, messgae: text))
                completion()
               
            }
            catch {
                messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
            }
        }
    }
    
    //MARK: - Stage 3
    func generatingItineary(_ message: String?, completion: @escaping() -> Void) {
        Task {
            do {
                let prompt = "i want to plan a trip to \(TravelInfo.toLocation) from \(TravelInfo.fromLocation) for \(TravelInfo.duration) day and my interest are \(TravelInfo.selectedInterest),and my food preference is non-veg please make detailed itenary with time for each day for me add also emoji and don't recommand any hotel for me."
                let response = try await chat?.sendMessage(prompt)
                
                guard let text = response?.text else {
                    messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                    return
                }
               
               
//                //MARK: - IF NEED TO CHANGE ANY PREVIOUS DETAIL
//                Task {
//                       do {
//                           let prompt = """
//                            You're designing a response system based on user input. If the user expresses satisfaction by saying "Yes, I like it," the system should respond with "Yes:1". However, if the user indicates a desire to modify details by saying "I want to change some details," the system should respond with "No:0". Handle both scenarios accordingly. If the user's response doesn't fit either case, return "N/A".
//
//                            \(String(describing: message))
//                            """
//                           
//
//                           let response = try await chat?.sendMessage(prompt)
//                           
//                           guard let text = response?.text else {
//                               messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
//                               return
//                           }
//                           
//                           var yesDetailVal: String?
//                           var noDetailVal: String?
//                           
//                           // Define regular expressions to match "Yes:1" and "No:0" patterns
//                           let yesRegex = try! NSRegularExpression(pattern: "(Yes:1)", options: .caseInsensitive)
//                           let noRegex = try! NSRegularExpression(pattern: "(No:0)", options: .caseInsensitive)
//
//                           // Match "Yes:1"
//                           if let yesMatch = yesRegex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {
//                               let yesDetail = String(text[Range(yesMatch.range, in: text)!])
//                               yesDetailVal = yesDetail
//                               print("Extracted Yes Detail: \(yesDetail)")
//                           } else {
//                               print("No 'Yes:1' detail found")
//                           }
//
//                           // Match "No:0"
//                           if let noMatch = noRegex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {
//                               let noDetail = String(text[Range(noMatch.range, in: text)!])
//                               print("Extracted No Detail: \(noDetail)")
//                               noDetailVal = noDetail
//                           } else {
//                               print("No 'No:0' detail found")
//                           }
//                           
//                           if yesDetailVal == "Yes:1" {
//                               /*
//                                Let's move to next stage since user confirm all his details
//                                */
////                               self.processState = .stageTwo
////                               let textMessage = "Let our AI know what kind of things you’d like to do on your trip!"
////                               messages.append(.init(role: .model, messgae: textMessage))
////                               self.isUpdate = false
////                               /*
////                                Suggesting interest and activity user can perform at that perticular locatio
////                                */
////                               Task {
////                                   do {
////                                       let prompt = "You are expert at suggesting interest, my user is planning a trip to \(String(describing: TravelInfo.toLocation)) location you have to suggest  all activity he can do in that place step by step in point \(messages) u have to asked for user input and confirmation "
////                                       let response = try await chat?.sendMessage(prompt)
////
////                                       guard let text = response?.text else {
////                                           messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
////                                           return
////                                       }
////
////                                       print(text)
////                                       messages.append(.init(role: .model, messgae: text))
////                                       self.isUpdate = false
////                                       completion()
////
////
////                                   }
////                                   catch {
////                                       messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
////                                   }
////                               }
//                           } else {
//                               /*
//                                Moving back to stage 1 as user want to update his details
//                                */
//                               self.processState = .stageOne
//
//                               Task {
//                                   do {
//                                       let prompt = "Previously we a planned my trip from \(String(describing: TravelInfo.fromLocation)) to \(String(describing: TravelInfo.toLocation)) for \(String(describing: TravelInfo.duration)) days and \(String(describing: TravelInfo.date)) date.Now Asked user what details he want to update and update only that perticular data and rest will be same"
//                                       let response = try await chat?.sendMessage(prompt)
//                                       
//                                       guard let text = response?.text else {
//                                           messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
//                                           return
//                                       }
//                                       
//                                       print(text)
//                                       messages.append(.init(role: .model, messgae: text))
//                                       self.isUpdate = true
//                                       completion()
//                                       
//                                      
//                                   }
//                                   catch {
//                                       messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
//                                   }
//                               }
//                           }
//
//                           completion() // Call completion after appending message
//                       }
//                       catch {
//                           messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
//                           completion() // Call completion after appending error message
//                       }
//                   }
                
                print(text)
                messages.append(.init(role: .model, messgae: text))
                completion()
               
            }
            catch {
                messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
            }
        }
    }
    

    
}



