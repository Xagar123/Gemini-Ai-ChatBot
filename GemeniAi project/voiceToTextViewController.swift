//
//  ViewController.swift
//  Voice to Text
//
//  Created by Sagar on 16/01/24.
//

import UIKit
import Speech
import AVFoundation


class voiceToTextViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    @IBOutlet weak var gifImageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
//    var videoView : UIImageView = {
//        let v = UIImageView()
//        v.translatesAutoresizingMaskIntoConstraints = false
//        return v
//    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //check if recognization is available
        SFSpeechRecognizer.requestAuthorization { authState in
            if authState == SFSpeechRecognizerAuthorizationStatus.authorized {
                //Speech recognization is authorised
                print("authorized success")
            }
        }
        
        // view.backgroundColor = .systemBackground
//        view.addSubview(videoView)
//        videoView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            videoView.topAnchor.constraint(equalTo: view.topAnchor),
//            videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            videoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//        ])
        
        let gradientLayer = CAGradientLayer()
                gradientLayer.frame = view.bounds

                // Define gradient colors
                let topColor = UIColor(hex: "#0A0A26").cgColor
                let bottomColor = UIColor(hex: "#0B0827").cgColor

                // Set gradient colors
                gradientLayer.colors = [topColor, bottomColor]

                // Set gradient locations (optional)
                gradientLayer.locations = [0.0, 1.0]

                // Add gradient layer to the view's layer
      //  self.view.layer.insertSublayer(gradientLayer, at: 0)
        
        setUpAnimation(fileName: "Natural AI brain brand element")
    }
    
    func startSpeechRecognition() {
        do {
            try startRecording()
        } catch {
            print("Error starting recording: \(error)")
        }
    }
    
    func startRecording() throws {
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup error: \(error)")
        }

        let inputNode: AVAudioInputNode? = audioEngine.inputNode

        guard let inputNode = inputNode else {
            print("Audio engine has no input node")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
        }

        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            // Handle recognition results here
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                print("Transcription: \(transcription)")
                self.textLabel.text = transcription
            } else if let error = error {
                print("Recognition error: \(error)")
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start error: \(error)")
        }
    }

    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }
    
    func resetAudioEngine() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest = nil
        recognitionTask = nil
        self.textLabel.text = ""
    }
    
    @IBAction func startButtonPressed(_ sender: UIButton) {
        startSpeechRecognition()
        
    }
    
    @IBAction func stopButtonPressed(_ sender: UIButton) {
        resetAudioEngine()
        stopRecording()
    }
    
    func setUpAnimation(fileName: String) {
        guard let gifURL = Bundle.main.url(forResource: fileName, withExtension: "gif") else {
            print("Could not find GIF file")
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            guard let gifData = try? Data(contentsOf: gifURL),
                  let imageSource = CGImageSourceCreateWithData(gifData as CFData, nil) else {
                print("Could not create image source from GIF data")
                return
            }
            let frameCount = CGImageSourceGetCount(imageSource)
            
            var frames = [UIImage]()
            
            for index in 0..<frameCount {
                guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, index, nil) else {
                    continue
                }
                let uiImage = UIImage(cgImage: cgImage)
                frames.append(uiImage)
            }
            
            DispatchQueue.main.async {
                self.gifImageView.animationImages = frames
                self.gifImageView.animationDuration = 2
                self.gifImageView.startAnimating()
            }
        }
    }
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
