//
//  ViewController.swift
//  SampleAPPCoreMLandVision
//
//  Created by HengVisal on 5/25/18.
//  Copyright © 2018 HengVisal. All rights reserved.
//

import UIKit
import AVKit //  AVKit ~ Use The Camera
import SnapKit // SnapKit ~ Setup Layout
import Vision // Machine Learning Library Using To detect object
import RxSwift
import RxCocoa

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    var dispose : DisposeBag = DisposeBag()
    var captureSession : AVCaptureSession!
    var previewLayer : AVCaptureVideoPreviewLayer!
    var predictLabel : UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createComponent()
        addSupview()
        setupLayout()
        
        captureAnalyzeFrame()
    }
}


// MARK: - Create UI Component
extension ViewController {
    func createComponent() -> Void {
        
                        // Setting Up Camera Caption
        
        // Capture Session
        captureSession = AVCaptureSession()
        
        // Add Input to Session
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {
            return }
        captureSession.addInput(input)
        captureSession.startRunning()
        
        // Add Preview Layer To give the Output to the application
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
                        // Setting Up Label Display
        predictLabel = UILabel()
        predictLabel.textAlignment = .center
        predictLabel.backgroundColor = UIColor.white
        predictLabel.textColor = UIColor.black
        predictLabel.font = predictLabel.font.withSize(20)
        predictLabel.numberOfLines = 0
        predictLabel.sizeToFit()
        
    }
}


// MARK: - Add Sup View
extension ViewController{
    func addSupview() -> Void {
        self.view.layer.addSublayer(previewLayer)
        self.view.addSubview(predictLabel)
    }
}
// MARK: - Setup UI Layout
extension ViewController {
    func setupLayout() -> Void {
        // Camera Layout
        previewLayer.frame = self.view.frame
        
        // PredictLabel
        predictLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(100)
        }
    }
}


// MARK: - Perform Screen Capture And Analyze
extension ViewController{
    func captureAnalyzeFrame() -> Void {
        
        // Capturing Frame from video
        let videoFrame = AVCaptureVideoDataOutput()
        videoFrame.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoFrame"))
        
        // Add output inorder to fire the delegate function
        captureSession.addOutput(videoFrame)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let cvPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else {return}
        let request = VNCoreMLRequest(model: model) { (response, err) in
            
            let responseObject = response.results as? [VNClassificationObservation]
            guard let result = responseObject?.first else {return}
            let resultText = result.identifier + " " + (result.confidence).description
            let resultObservale = Observable.just(resultText)
            
            resultObservale
                .distinctUntilChanged()
                .map{$0.description}
                .bind(to: self.predictLabel.rx.text)
                .disposed(by: self.dispose)
            
        }
        try? VNImageRequestHandler(cvPixelBuffer: cvPixelBuffer, options: [:]).perform([request])
    }
}

