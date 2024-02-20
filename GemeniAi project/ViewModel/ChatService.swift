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
    var chat: Chat?
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
    var stageSecondProcessState: StageSecondUserState = .isBudgetPreferenceSelected
    
    var isUpdate:Bool = false
    var reloadTableViewClosure: (() -> Void)?
    
    func sendMessage(_ message: String,chatRole:ChatRole,completion: @escaping () -> Void) {
        
//        if (chat == nil) {
//            let history: [ModelContent] = messages.map { ModelContent(role: $0.role == .user ? "user" : "model", parts: $0.messgae)}
//            chat = GenerativeModel(name: "gemini-pro", apiKey: "AIzaSyCMRaH7pJV0r5PbH6yGmNn0HgWNK2_2f4Q").startChat(history: history)
//        }
        
        // MARK: Add user's message to the list
//        messages.append(.init(role: .user, messgae: message))
        Task {
               do {
//                   let prompt = """
// you are an AI travel assistant and whatever user enter give response in short and precise but user interactive and say how can i assist u to plan a trip and use emoji, and from the user input u have to extract To locaton place name(very important)(if any specific place name is given then extract the city or state name) and from location name(very important) and duration you have to ask user for this detail till he enter,
// You need to take four inputs from the user one after getting the other,Ask this question step by step for first time just ask To location and so on and extract this detail To location,From location and duration dont ask unnessary detail just this much and give me one by one once you got all details But keep in mind don't ever try to suggested any itinerary or don't say is there something else i can help you. your job is to ask for confirmation yes or no with full trip details. \(messages)
// """
                   let prompt = """
                   you are an AI travel assistant and whatever user enter give response in short and precise but user interactive and say how can i assist u to plan a trip and use emoji,
                   You need to take four inputs from the user one after getting the other
                   Ask this question step by step for first time just ask 1st and so on
                   1. You need to take To location name((if any specific place name is given then extract the city or state name)) Very important
                   2. You need to take From location name Very Important
                   3. Ask for duration in days or number of days
                   4. Ask for Dates(should be 2024)
                   once you get all this details then at the end show the summary and ask for confirmation just yes or no.
                   Don't give any dummy example
                   You can answer any general question if user ask for suggestion suggest him 
                   But keep in mind don't ever try to suggested any itinerary or don't say is there something else i can help you. your job is to ask for confirmation yes or no with full trip details.
                   \(messages)
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
                                   
                                   TravelInfo.shared.toLocation = aiResponse[startIndex..<endIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                               } else {
                                   // If "To:" is not found, set default value
                                   TravelInfo.shared.toLocation = TravelInfo.shared.toLocation
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
                                   
                                   TravelInfo.shared.fromLocation = aiResponse[startIndex..<endIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                               } else {
                                   // If "From:" is not found, set default value
                                   TravelInfo.shared.fromLocation = TravelInfo.shared.fromLocation
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
                                   
                                   TravelInfo.shared.duration = aiResponse[startIndex..<endIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                               } else {
                                   // If "Duration:" is not found, set default value
                                   TravelInfo.shared.duration = TravelInfo.shared.duration
                               }
                               
                               if let dateRange = aiResponse.range(of: "Date:") {
                                   // If "Date:" is found, extract the substring after "Date:"
                                   let startIndex = dateRange.upperBound
                                   let endIndex = aiResponse.endIndex
                                   
                                   TravelInfo.shared.date = aiResponse[startIndex..<endIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                               } else {
                                   // If "Date:" is not found, set default value
                                   TravelInfo.shared.date = TravelInfo.shared.date
                               }
                               
                               print("To:", TravelInfo.shared.toLocation ?? "N/A")
                               print("From:", TravelInfo.shared.fromLocation ?? "N/A")
                               print("Duration:", TravelInfo.shared.duration ?? "N/A")
                               print("Date:", TravelInfo.shared.date ?? "N/A")
                               
                               if (TravelInfo.shared.toLocation != "N/A") && (TravelInfo.shared.fromLocation != "N/A") && (TravelInfo.shared.duration != "N/A") {
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
    func initialWelcomeMessage(completion: @escaping () -> Void) {
        
        if (chat == nil) {
            let history: [ModelContent] = messages.map { ModelContent(role: $0.role == .user ? "user" : "model", parts: $0.messgae)}
            chat = GenerativeModel(name: "gemini-pro", apiKey: "AIzaSyCMRaH7pJV0r5PbH6yGmNn0HgWNK2_2f4Q").startChat(history: history)
        }
        
        
        Task {
               do {
                   let prompt = "You are an Travel buddy, You have to thanks our user for using this service and don't asked preferences and budget or itinerary  just You need  welcome our user and need to  asked how can I plan your trip in {single line}"
                   let response = try await chat?.sendMessage(prompt)
                   
                   guard let text = response?.text else {
                       messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                       return
                   }
                 
                   print(text)
                   messages.append(.init(role: .model, messgae: text))
                   completion()
               }
               catch {
                   messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
                   completion()
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
//                       let textMessage = "Let our AI know what kind of things you’d like to do on your trip!"
                       let textMessage = """
                        Could you please specify your preference in terms of budget: are you looking for something
                        1.budget-friendly,
                        2.comfortable,
                        3.luxurious?
                        """
                       messages.append(.init(role: .model, messgae: textMessage))
                       self.isUpdate = false
                       /*
                        Suggesting interest and activity user can perform at that perticular locatio
                        */
//                        Need to implement don't discard
//                       Task {
//                           do {
//                               let prompt = "i want to go to \(String(describing: TravelInfo.toLocation)), you need to suggest me what all interest/activity available in the \(String(describing: TravelInfo.toLocation)) and give only 6 best interest/activity only tittle name length max 0 - 5 letters."
//                               let response = try await model.generateContent(prompt)
//                               
//                               guard let text = response.text else {
//                                   messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
//                                   return
//                               }
//                               
//                               print(text)
//                               let dataArray = text.components(separatedBy: "\n")
//                               TravelInfo.destInterest = dataArray
//                               let selectedButtons = [dataArray[0], dataArray[2], dataArray[4]]
//                               let selectedOptions = selectedButtons.joined(separator: ", ")
//                               TravelInfo.selectedInterest = selectedOptions
//                               
//                               print(selectedOptions)
//                               print(dataArray)
//                               messages.append(.init(role: .model, messgae: text))
//                               
//                               // custome message
//                               messages.append(.init(role: .model, messgae: "Generating itineary for you"))
//                               self.isUpdate = true
//                               self.processState = .stageThree
//                               completion()
//                               
//                              
//                           }
//                           catch {
//                               messages.append(.init(role: .model, messgae: "Something went wrong, please try again."))
//                           }
//                       }
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
                let prompt = "i am planning a trip form \(String(describing: TravelInfo.shared.fromLocation)) to \(String(describing: TravelInfo.shared.toLocation)) for \(String(describing: TravelInfo.shared.duration)) asked for confirmation "
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
                                       let prompt = "Previously we a planned my trip from \(String(describing: TravelInfo.shared.fromLocation)) to \(String(describing: TravelInfo.shared.toLocation)) for \(String(describing: TravelInfo.shared.duration)) days and \(String(describing: TravelInfo.shared.date)) date.Now Asked user what details he want to update and update only that perticular data and rest will be same"
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
                let prompt = "i want to plan a trip to \(TravelInfo.shared.toLocation) from \(TravelInfo.shared.fromLocation) for \(TravelInfo.shared.duration) day and my interest are \(TravelInfo.shared.selectedInterest),and my food preference is non-veg please make detailed itenary with time for each day for me add also emoji and don't recommand any hotel for me."
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





