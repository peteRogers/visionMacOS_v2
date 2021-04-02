//
//  ViewController.swift
//  visionMacOS_v2
//
//  Created by Peter Rogers on 01/04/2021.
//

/* Tested in macOS Mojave (Dec 31, 2018) using Xcode 10.1
*  1. Create a new Xcode project
*  2. Select macOS
*  3. Pick Cocoa App, give it a name, create
*  4. Open the project setting, click "Capabilities", goto "App Sandbox" -> "Hardware" -> check "Camera"
*  5. Open Info.plist of the project, and add row "Privacy - Camera Usage Description", give it some description
*  6. Open ViewController, and paste the code below
*  7. Click Play icon, give Cam access permissson "OK"
*  8. Voila! Preview screen!
*/
import Cocoa
import AVFoundation
import Vision


class ViewController: NSViewController,  AVCaptureVideoDataOutputSampleBufferDelegate, NSWindowDelegate{
    var bufferSize: CGSize = .zero
    
    private var previewLayer: AVCaptureVideoPreviewLayer! = nil
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let session = AVCaptureSession()
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    private var videoDevice:AVCaptureDevice!
    @IBOutlet weak var previewView: NSView!
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // to be implemented in the subclass
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        previewView.wantsLayer = true
        setupAVCapture()
        
    }
    
    override func viewDidAppear() {
        view.window?.delegate = self
       // view.window?.toggleFullScreen(self)
        
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        //switch everything off before quitting
        //self.serialPort?.close()
        
        session.stopRunning()
        
        NSApplication.shared.terminate(self)
        return true
    }
    
    
    func setupAVCapture() {
        var deviceInput: AVCaptureDeviceInput!
        
        // Select a video device, make an input
        videoDevice = AVCaptureDevice.default(for: .video)
       
        do {
            deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
           
           
        } catch {
            print("Could not create video device input: \(error)")
            return
        }
        
        session.beginConfiguration()
        session.sessionPreset = .low // Model image size is smaller.
        
        // Add a video input
        guard session.canAddInput(deviceInput) else {
            print("Could not add video device input to the session")
            session.commitConfiguration()
            return
        }
        session.addInput(deviceInput)
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            // Add a video data output
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            print("Could not add video data output to the session")
            session.commitConfiguration()
            return
        }
        let captureConnection = videoDataOutput.connection(with: .video)
        // Always process the frames
        captureConnection?.isEnabled = true
        do {
            try  videoDevice!.lockForConfiguration()
           
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            
            videoDevice!.unlockForConfiguration()
        } catch {
            print(error)
        }
        session.commitConfiguration()
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewView.layer = previewLayer

       
    }
    
    func startCaptureSession() {
        session.startRunning()

    }
    
    // Clean up capture setup
    func teardownAVCapture() {
        previewLayer.removeFromSuperlayer()
        previewLayer = nil
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput, didDrop didDropSampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("frame dropped")
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

