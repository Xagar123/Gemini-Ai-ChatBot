//
//  API_KEY.swift
//  GemeniAi project
//
//  Created by Sagar on 18/01/24.
//

import Foundation

enum APIKey {
    // Fetch the API key from *GenerativeAI-Info.plist
    
    static var `default`:String {
        guard let filePath = Bundle.main.path(forResource: "GenerativeAI-Info", ofType: "plist") else {
            return ""
          //  fatalError("Couldn't find file 'GenerativeAI-Info.plist'.")
        }
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "API_KEY") as? String else {
            fatalError("Couldn't find key 'API KEY' in 'GenerativeAI-Info.plist'.")
        }
        
        if value.starts(with: "_") {
            fatalError(" Check code again ")
        }
        return value
    }
}
