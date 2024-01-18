//
//  ViewController.swift
//  GemeniAi project
//
//  Created by Sagar on 18/01/24.
//

import UIKit
import GoogleGenerativeAI

class ViewController: UIViewController {
    
    let model = GenerativeModel(name: "gemini-pro", apiKey: "")
    var inputText = ""
    var aiResponse = "Hello! how can i help you today"

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }


}

