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

class ViewController: UIViewController,UITextViewDelegate {
    
    let model = GenerativeModel(name: "gemini-pro", apiKey: "AIzaSyCMRaH7pJV0r5PbH6yGmNn0HgWNK2_2f4Q")
    var inputText = ""
    var aiResponse = "Hello! how can i help you today"
    
    
    @IBOutlet weak var textViewField: UITextView!
    @IBOutlet weak var textViewHC: NSLayoutConstraint!
    @IBOutlet weak var responseList: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textViewField.delegate = self
        textViewField.isScrollEnabled = false
        adjustTextViewHeight()
        textViewHC.constant = 50
        
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
        sendMessage()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.adjustTextViewHeight()
    }
  

}


