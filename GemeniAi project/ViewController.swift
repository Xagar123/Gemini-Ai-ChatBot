//
//  ViewController.swift
//  GemeniAi project
//
//  Created by Sagar on 18/01/24.
//

import UIKit
import GoogleGenerativeAI
import AVKit
import AVFoundation
import IQKeyboardManagerSwift

class ViewController: UIViewController,UITextViewDelegate, voiceToTextInput {
    
    
    let model = GenerativeModel(name: "gemini-pro", apiKey: "AIzaSyCMRaH7pJV0r5PbH6yGmNn0HgWNK2_2f4Q")
    var inputText = ""
//    var aiResponse = "Hello! how can i help you today"
    var chatMessages: [(sender: String, message: String)] = []
    
    
    @IBOutlet weak var textViewField: UITextView!
    @IBOutlet weak var textViewHC: NSLayoutConstraint!
    @IBOutlet weak var responseList: UILabel!
    @IBOutlet weak var sendAndMicBtn: UIButton!
    @IBOutlet weak var sendAndMicBtnIcon: UIImageView!
    
    @IBOutlet weak var loadingGif: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var botView: UIImageView!
    let activityIndicator = UIActivityIndicatorView()
    
    
    var responseArr = [String]()
    var isMicEnable = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textViewField.delegate = self
        textViewField.isScrollEnabled = false
        adjustTextViewHeight()
        textViewHC.constant = 50
        
        activityIndicator.style = .large
                activityIndicator.hidesWhenStopped = true
                activityIndicator.center = view.center
        activityIndicator.color = UIColor.white
                view.addSubview(activityIndicator)
        view.bringSubviewToFront(activityIndicator)
        
        
    
        sendAndMicBtnIcon.image = UIImage(systemName: "mic.circle")
        self.textViewField.clipsToBounds = true
        self.textViewField.layer.cornerRadius = 10
//        setUpAnimation(fileName: "AI", gifImageView: self.botView)
//        self.botView.isHidden = true
        
        self.applyGraident(textViewField as Any)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "ResponseTableViewCell", bundle: nil), forCellReuseIdentifier: "ResponseTableViewCell")
        
        textViewField.text = " Enter your text here..."
        textViewField.textColor = UIColor.white
        
        
        // Add tap gesture recognizer to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
    }
    
    //MARK: - Fetch Response
    func sendMessage() {
//        aiResponse = ""
        Task {
            do{
                let response = try await model.generateContent(textViewField.text)
//                let response = try await model.startChat(history: <#T##[ModelContent]#>)
                guard let text = response.text else {
                    textViewField.text = "Sorry, I could not process that. InPlease try again"
                    return
                }
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.view.isUserInteractionEnabled = true
                    self.textViewField.text = ""
                    self.receiveMessage(sender: "AI", message: text)
//                    self.aiResponse = text
                    print(text)
                    self.sendAndMicBtnIcon.image = UIImage(systemName: "mic.circle")
//                    self.responseArr.append(text)
                    self.isMicEnable = true
//                    self.botView.isHidden = true
                    self.tableView.isHidden = false
                    self.textViewHC.constant = 50
                    IQKeyboardManager.shared.resignFirstResponder()
                    self.tableView.reloadData()
                    self.scrollToBottom()
                }

                
            } catch {
//                aiResponse = "Something went wrong.. \n\(error.localizedDescription)"
                print(error.localizedDescription)
            }
        }
    }
    
    func sendMessage(sender: String, message: String) {
        chatMessages.append((sender, message))
        tableView.reloadData()
        scrollToBottom()
    }
    
    func receiveMessage(sender: String, message: String) {
        sendMessage(sender: sender, message: message)
    }
    
    func scrollToBottom() {
        if chatMessages.count > 0 {
            let indexPath = IndexPath(row: chatMessages.count - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    func adjustTextViewHeight() {
        // Calculate the new content size
        let newSize = textViewField.sizeThatFits(CGSize(width: textViewField.frame.width, height: CGFloat.greatestFiniteMagnitude))
        
        // Update the height constraint based on the new content size
        //        textViewHC.constant = newSize.height
        textViewHC.constant = max(50, newSize.height)
        
        // Optionally, you can animate the height change for a smooth transition
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
            self.applyGraident(self.textViewField as Any)
        }
    }
    
    @IBAction func sendBtnTapped(_ sender: UIButton) {
        print(textViewField.text!)
        
        if (TravelInfo.toLocation != "N/A") && (TravelInfo.fromLocation != "N/A") && (TravelInfo.duration != "N/A") && (TravelInfo.date != "N/A") {
            
            self.view.isUserInteractionEnabled = true
            self.textViewField.text = ""
            let customText = "Good to go! Let's start planning your trip."
            self.receiveMessage(sender: "AI", message: customText)
            
//        }
//        if (TravelInfo.toLocation == "N/A") || (TravelInfo.fromLocation == "N/A") || (TravelInfo.duration != "N/A") || (TravelInfo.date == "N/A"){
//            
//            // Data is missing, prompt for missing information
//            var customText = "I need some additional information. "
//            self.view.isUserInteractionEnabled = true
//            self.textViewField.text = ""
//            
//            if TravelInfo.toLocation == "N/A" {
//                customText += "Where would you like to go? "
//            }
//            
//            if TravelInfo.fromLocation == "N/A" {
//                customText += "Where are you departing from? "
//            }
//            
//            if TravelInfo.duration == "N/A" {
//                customText += "How long will you stay there? "
//            }
//            
//            if TravelInfo.date == "N/A" {
//                customText += "When are you planning to go? "
//            }
//            
//            self.receiveMessage(sender: "AI", message: customText)
//            
//        
        }else {
            
            
            Task{
                do{
                    
                    let prompt = """
                Given user input, you are a travel AI tasked with extracting the 'To' and 'From' location names in the format 'To:' and 'From:'.
                If the user misplaces either word, refactor it accordingly and take the first place. If a location is missing, set it as 'N/A'.
                Note that if the user enters 'I want to go to or from [from place]', if To location is missing then return To:N/A and From:.
                extract this extra data if user provide
                if user enter his duration example for number of days then formate in Duration:
                and if user gives number of days then formate in form of Date:
                or if he give only staring date then calculate the remaning days and give both in formate Date:
                . My user input is \(textViewField.text)
                """
                    
                    let response = try await model.generateContent(prompt)
                    guard let text = response.text else {
                        textViewField.text = "Sorry, I could not process that. Please try again"
                        return
                    }
                    let aiResponse = text
                    
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
                        TravelInfo.toLocation = "N/A"
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
                        TravelInfo.fromLocation = "N/A"
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
                        TravelInfo.duration = "N/A"
                    }

                    if let dateRange = aiResponse.range(of: "Date:") {
                        // If "Date:" is found, extract the substring after "Date:"
                        let startIndex = dateRange.upperBound
                        let endIndex = aiResponse.endIndex

                        TravelInfo.date = aiResponse[startIndex..<endIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                    } else {
                        // If "Date:" is not found, set default value
                        TravelInfo.date = "N/A"
                    }

                    
                    print("To:", TravelInfo.toLocation ?? "N/A")
                    print("From:", TravelInfo.fromLocation ?? "N/A")
                    print("Duration:", TravelInfo.duration ?? "N/A")
                    print("Date:", TravelInfo.date ?? "N/A")
                    
                  
                    self.activityIndicator.stopAnimating()
                    
                    if TravelInfo.toLocation != "N/A" && TravelInfo.fromLocation != "N/A" && TravelInfo.duration != "N/A" && TravelInfo.date != "N/A" {
                        // All data is available
                        var customText = "Great! I have all the necessary information. What would you like to explore in \(TravelInfo.toLocation!)?"
                        self.view.isUserInteractionEnabled = true
                        self.textViewField.text = ""
                        self.receiveMessage(sender: "AI", message: customText)
                        
                    } else if TravelInfo.toLocation == "N/A" && TravelInfo.fromLocation == "N/A" && TravelInfo.duration == "N/A" && TravelInfo.date == "N/A" {
                        // All data is missing
                        let customText = "I'm your travel buddy AI! Let's plan your trip together. Where would you like to go?"
                        self.view.isUserInteractionEnabled = true
                        self.textViewField.text = ""
                        self.receiveMessage(sender: "AI", message: customText)
                        
                    } else {
                        // Data is missing, prompt for missing information
                        var customText = "I need some additional information. "
                        self.view.isUserInteractionEnabled = true
                        self.textViewField.text = ""
                        
                        if TravelInfo.toLocation == "N/A" {
                            customText += "Where would you like to go? "
                        }
                        
                        if TravelInfo.fromLocation == "N/A" {
                            customText += "Where are you departing from? "
                        }
                        
                        if TravelInfo.duration == "N/A" {
                            customText += "How long will you stay there? "
                        }
                        
                        if TravelInfo.date == "N/A" {
                            customText += "When are you planning to go? "
                        }
                        
                        self.receiveMessage(sender: "AI", message: customText)
                    }

                } catch {
                    self.activityIndicator.stopAnimating()
                    print(error.localizedDescription)
                }
            }
        }

       
        
        if isMicEnable {
//            self.loadingGif.isHidden = false
//            self.botView.isHidden = true
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "voiceToTextViewController") as? voiceToTextViewController else { return }
            viewController.delegate = self
            let navVc = UINavigationController(rootViewController: viewController)
            navVc.modalPresentationStyle = .fullScreen
            navVc.modalTransitionStyle = .crossDissolve
            present(navVc, animated: true)
            
        } else {
//            self.loadingGif.isHidden = false
            DispatchQueue.main.async {
                self.activityIndicator.startAnimating()
                self.view.isUserInteractionEnabled = false
//                self.tableView.isHidden = true
//                self.botView.isHidden = false
                if let userMessage = self.textViewField.text, !userMessage.isEmpty {
                    self.sendMessage(sender: "User", message: userMessage)
//                    self.textViewField.text = nil

                }
//                self.responseArr.append(self.textViewField.text)
//                self.sendMessage()
                
                
                
                IQKeyboardManager.shared.resignFirstResponder()
            }
            
        }
        
    }
    
    
    func applyGraident(_ property: Any) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = textViewField.bounds
        gradientLayer.colors = [
            UIColor(red: 0/255, green: 241/255, blue: 198/255, alpha: 1).cgColor,
            UIColor(red: 45/255, green: 56/255, blue: 153/255, alpha: 0.93).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.locations = [0.0, 1.0]
        
        // Apply the gradient to the text field's layer
//        textViewField.layer.insertSublayer(gradientLayer, at: 0)
        (property as AnyObject).layer.insertSublayer(gradientLayer, at: 0)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    //MARK: - TextField
    func textViewDidChange(_ textView: UITextView) {
        self.adjustTextViewHeight()
        // Check if the text view is empty
        let isTextViewEmpty = textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        if isTextViewEmpty {
            sendAndMicBtnIcon.image = UIImage(systemName: "mic.circle")
            self.isMicEnable = true
        } else {
            sendAndMicBtnIcon.image = UIImage(systemName: "paperplane.circle.fill")
            self.isMicEnable = false
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // Clear the placeholder text when the user starts typing
        if textView.text == " Enter your text here..." {
            textView.text = ""
            textView.textColor = UIColor.white
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        // Set the placeholder text again if the text view is empty
        if textView.text.isEmpty {
            textView.text = " Enter your text here..."
            textView.textColor = UIColor.white
        }
    }
    
    //MARK: - VoiceToText Delegate
    func voiceToTextData(_ userInput: String) {
        
        if userInput == " " {
            return
        }

        print("Voice to text input \(userInput)")
        self.textViewField.text = userInput
        self.responseArr.append(userInput)
        self.activityIndicator.startAnimating()
        sendMessage()
        
    }
    
    
}


extension ViewController: UITableViewDelegate,UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ResponseTableViewCell", for: indexPath) as? ResponseTableViewCell else {
            return UITableViewCell()
        }
        
        cell.profilePic.layer.cornerRadius = cell.profilePic.frame.height / 2
        
        
        cell.responseLabel.textColor = UIColor.white
        
        let (sender, message) = chatMessages[indexPath.row]

        if sender == "User" {
            cell.nameLbl.text = "You"
            cell.profilePic.tintColor = UIColor.init(hex: "4595AA")
            cell.profilePic.image = UIImage(systemName: "person.crop.circle.dashed")
            cell.responseLabel.text = message
        } else {
            cell.nameLbl.text = "MynBot"
            cell.profilePic.tintColor = UIColor.red
            cell.profilePic.image = UIImage(named: "logo")
            cell.responseLabel.text = message
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}
