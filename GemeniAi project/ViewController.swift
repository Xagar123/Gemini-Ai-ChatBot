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
    var aiResponse = "Hello! how can i help you today"
    
    
    @IBOutlet weak var textViewField: UITextView!
    @IBOutlet weak var textViewHC: NSLayoutConstraint!
    @IBOutlet weak var responseList: UILabel!
    @IBOutlet weak var sendAndMicBtn: UIButton!
    @IBOutlet weak var sendAndMicBtnIcon: UIImageView!
    
    @IBOutlet weak var loadingGif: UIImageView!
    
    
    
    var isMicEnable = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textViewField.delegate = self
        textViewField.isScrollEnabled = false
        adjustTextViewHeight()
        textViewHC.constant = 50
    
        sendAndMicBtnIcon.image = UIImage(systemName: "mic.circle")
        self.textViewField.layer.cornerRadius = 20
        
//        setUpAnimation(fileName: "Organic Artificial Intelligence design for milkinside", gifImageView: self.loadingGif)
    }
    
    //MARK: - Fetch Response
    func sendMessage() {
        aiResponse = ""
        Task {
            do{
                let response = try await model.generateContent(textViewField.text)
                guard let text = response.text else {
                    textViewField.text = "Sorry, I could not process that. InPlease try again"
                    return
                }
                textViewField.text = ""
                aiResponse = text
                print(text)
//                self.loadingGif.isHidden = true
                self.responseList.text = text
                
                
            } catch {
                aiResponse = "Something went wrong.. \n\(error.localizedDescription)"
            }
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
        }
    }
    
    @IBAction func sendBtnTapped(_ sender: UIButton) {
        print(textViewField.text!)
        
        if isMicEnable {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "voiceToTextViewController") as? voiceToTextViewController else { return }
            viewController.delegate = self
            let navVc = UINavigationController(rootViewController: viewController)
            navVc.modalPresentationStyle = .fullScreen
            navVc.modalTransitionStyle = .crossDissolve
            present(navVc, animated: true)
            
        } else {
//            self.loadingGif.isHidden = false
            sendMessage()
            IQKeyboardManager.shared.resignFirstResponder()
        }
        
        
    }
    
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
    
    //MARK: - VoiceToText Delegate
    func voiceToTextData(_ userInput: String) {
        self.responseList.text = ""
        print("Voice to text input \(userInput)")
        self.textViewField.text = userInput
        sendMessage()
        
    }
    
    
}


