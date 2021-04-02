/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Contains the object recognition view controller for the Breakfast Finder.
*/

import Cocoa
import AVFoundation
import Vision

class VisionObjectRecognitionViewController: ViewController {
    
    private var detectionOverlay: CALayer! = nil
    
    // Vision parts
    private var requests = [VNRequest]()
    var outString = ""
    let faceDetection = VNDetectFaceRectanglesRequest()
    let faceLandmarks = VNDetectFaceLandmarksRequest()
    let faceLandmarksDetectionRequest = VNSequenceRequestHandler()
    let faceDetectionRequest = VNSequenceRequestHandler()
    
   
    
    func readData(){
        let filename = getDocumentsDirectory().appendingPathComponent("output.txt")
        do {
                let text2 = try String(contentsOf: filename, encoding: .utf8)
                outString = text2
            }
            catch {print(error)
                
            }
        
        
    }
    
    
    func saveData(){
        
        
        let filename = getDocumentsDirectory().appendingPathComponent("output.txt")
        print(filename)
        do {
            try outString.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("failed to write")
            print(error)
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        }
        
    }
    
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
   
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        let attachments = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate)
        let ciImage = CIImage(cvImageBuffer: pixelBuffer, options: attachments as! [CIImageOption : Any]?)
       
        detectFace(on:ciImage)

    }
    
    
    func detectFace(on image: CIImage) {
            try? faceDetectionRequest.perform([faceDetection], on: image)
            if let results = faceDetection.results as? [VNFaceObservation] {
                if !results.isEmpty {
                    faceLandmarks.inputFaceObservations = results
                    detectLandmarks(on: image)
                    
                    DispatchQueue.main.async {
                       // self.shapeLayer.sublayers?.removeAll()
                    }
                }
            }
        }
    
    func detectLandmarks(on image: CIImage) {
            try? faceLandmarksDetectionRequest.perform([faceLandmarks], on: image)
            if let landmarksResults = faceLandmarks.results as? [VNFaceObservation] {
                for observation in landmarksResults {
                    //print("roll: \(observation.roll!) yaw: \(observation.yaw!)")
                    if(observation.roll! != 0 || observation.yaw! != 0){
                        
                        let date = Date()
                        let df = DateFormatter()
                        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        let dateString = df.string(from: date)
                        let s = "\n\(observation.roll!), \(observation.yaw!), \(dateString)"
                        outString = outString.appending(s)
                        saveData()
                    }

                }
            }
        }
    
    override func setupAVCapture() {
        super.setupAVCapture()
        readData()
        startCaptureSession()
        
    }
    
}
