//
//  ViewController.swift
//  Voice to Text
//
//  Created by Sagar on 16/01/24.
//

import UIKit
import Speech
import AVFoundation

protocol voiceToTextInput {
    func voiceToTextData(_ userInput: String)
}


class voiceToTextViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    @IBOutlet weak var previousIcon: UIButton!
    @IBOutlet weak var gifImageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!

    var isPlaying = true
    @IBOutlet weak var playPauseIcon: UIImageView!
    
    @IBOutlet weak var crossAndSendBtn: UIButton!
    
    var delegate:voiceToTextInput?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.playPauseIcon.tintColor = UIColor.blue
        self.crossAndSendBtn.tintColor = UIColor.blue
        self.previousIcon.tintColor = UIColor.blue
        UIColor().setupGradient(topColor: "#0A0A26", bottomColor: "#0B0827", view: self.view)
        //check if recognization is available
        SFSpeechRecognizer.requestAuthorization { authState in
            if authState == SFSpeechRecognizerAuthorizationStatus.authorized {
                //Speech recognization is authorised
                print("authorized success")
            }
        }
        
        playPauseIcon.image = UIImage(systemName: "pause.circle")
        startSpeechRecognition()
        // view.backgroundColor = .systemBackground
//        view.addSubview(videoView)
//        videoView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            videoView.topAnchor.constraint(equalTo: view.topAnchor),
//            videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            videoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//        ])
        
        
                // Add gradient layer to the view's layer
      //  self.view.layer.insertSublayer(gradientLayer, at: 0)
        
        setUpAnimation(fileName: "Natural AI brain brand element", gifImageView: self.gifImageView)
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
//        self.textLabel.text = ""
    }
    
    @IBAction func startButtonPressed(_ sender: UIButton) {
        startSpeechRecognition()
        
    }
    
    @IBAction func stopButtonPressed(_ sender: UIButton) {
        resetAudioEngine()
        stopRecording()
    }
    
    @IBAction func playPauseBtn(_ sender: UIButton) {
        
        isPlaying.toggle()
        
        if isPlaying {
            
            playPauseIcon.image = UIImage(systemName: "pause.circle")
           // UIColor().setupGradient(topColor: "#0A0A26", bottomColor: "#0B0827", view: self.view)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.playPauseIcon.tintColor = UIColor.blue
                self.crossAndSendBtn.tintColor = UIColor.blue
                self.previousIcon.tintColor = UIColor.blue
                self.textLabel.textColor = UIColor.white
                self.view.backgroundColor = UIColor.init(hex: "#0B0827")
                }
            
            setUpAnimation(fileName: "Natural AI brain brand element", gifImageView: self.gifImageView)
//            resetAudioEngine()
//            stopRecording()
            startSpeechRecognition()
            self.crossAndSendBtn.setImage(UIImage(systemName: "x.circle"), for: .normal)
        }else {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.playPauseIcon.tintColor = UIColor.orange
                self.crossAndSendBtn.tintColor = UIColor.orange
                self.previousIcon.tintColor = UIColor.orange
                self.view.backgroundColor = .white
                self.textLabel.textColor = UIColor.black
                }
           
            setUpAnimation(fileName: "Asistente", gifImageView: self.gifImageView)
            playPauseIcon.image = UIImage(systemName: "mic.circle")
            self.crossAndSendBtn.setImage(UIImage(systemName: "paperplane.circle.fill"), for: .normal)
            resetAudioEngine()
            stopRecording()
        }
    }
    
    @IBAction func previousBtnTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @IBAction func crossAndSendBtn(_ sender: UIButton) {
        if isPlaying {
            print("cross btn")
            self.textLabel.text = ""
            resetAudioEngine()
            stopRecording()
            startSpeechRecognition()
        }else {
            print("send btn")
            self.delegate?.voiceToTextData(self.textLabel.text ?? "")
            self.dismiss(animated: true)
           
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

extension UIViewController {
    func setUpAnimation(fileName: String, gifImageView: UIImageView) {
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
                gifImageView.animationImages = frames
                gifImageView.animationDuration = 2
                gifImageView.startAnimating()
            }
        }
    }
}

extension UIColor {
    
    func setupGradient(topColor : String, bottomColor : String, view:UIView){
        let gradientLayer = CAGradientLayer()
                gradientLayer.frame = view.bounds

                // Define gradient colors
                let topColor = UIColor(hex: topColor).cgColor
                let bottomColor = UIColor(hex: bottomColor).cgColor

                // Set gradient colors
                gradientLayer.colors = [topColor, bottomColor]

                // Set gradient locations (optional)
                gradientLayer.locations = [0.0, 1.0]

    }
}
