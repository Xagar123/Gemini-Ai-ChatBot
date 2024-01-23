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
        aiResponse = ""
        Task {
            do{
                let response = try await model.generateContent(textViewField.text)
                guard let text = response.text else {
                    textViewField.text = "Sorry, I could not process that. InPlease try again"
                    return
                }
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.view.isUserInteractionEnabled = true
                    self.textViewField.text = ""
                    self.aiResponse = text
                    print(text)
                    self.sendAndMicBtnIcon.image = UIImage(systemName: "mic.circle")
                    self.responseArr.append(text)
                    self.isMicEnable = true
//                    self.botView.isHidden = true
                    self.tableView.isHidden = false
                    self.textViewHC.constant = 50
                    IQKeyboardManager.shared.resignFirstResponder()
                    self.tableView.reloadData()
                }

                
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
            self.applyGraident(self.textViewField as Any)
        }
    }
    
    @IBAction func sendBtnTapped(_ sender: UIButton) {
        print(textViewField.text!)
        
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
                self.responseArr.append(self.textViewField.text)
                self.sendMessage()
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

        print("Voice to text input \(userInput)")
        self.textViewField.text = userInput
        self.responseArr.append(userInput)
        self.activityIndicator.startAnimating()
        sendMessage()
        
    }
    
    
}


extension ViewController: UITableViewDelegate,UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return responseArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ResponseTableViewCell", for: indexPath) as? ResponseTableViewCell else {
            return UITableViewCell()
        }
        
        cell.profilePic.layer.cornerRadius = cell.profilePic.frame.height / 2
        
        cell.responseLabel.text = responseArr[indexPath.row]
        cell.responseLabel.textColor = UIColor.white
        
        if indexPath.row % 2 == 0 {
            cell.nameLbl.text = "You"
            cell.profilePic.tintColor = UIColor.init(hex: "4595AA")
            cell.profilePic.image = UIImage(systemName: "person.crop.circle.dashed")
        }else {
            cell.nameLbl.text = "MynBot"
            cell.profilePic.tintColor = UIColor.red
            cell.profilePic.image = UIImage(named: "logo")
            
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}
