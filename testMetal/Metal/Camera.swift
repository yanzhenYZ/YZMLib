import Foundation
import AVFoundation
import Metal

//public class Camera: NSObject, ImageSource, AVCaptureVideoDataOutputSampleBufferDelegate {
public class Camera: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    public var renderView: RenderView!
    public let captureSession:AVCaptureSession
    public let inputCamera:AVCaptureDevice!
    let videoInput:AVCaptureDeviceInput!
    let videoOutput:AVCaptureVideoDataOutput!
    var videoTextureCache: CVMetalTextureCache?
    
    var supportsFullYUVRange:Bool = false
    let captureAsYUV:Bool
    let yuvConversionRenderPipelineState:MTLRenderPipelineState?
    var yuvLookupTable:[String:(Int, MTLDataType)] = [:]
    
    let frameRenderingSemaphore = DispatchSemaphore(value:1)
    let cameraProcessingQueue = DispatchQueue.global()
    let cameraFrameProcessingQueue = DispatchQueue(
        label: "com.sunsetlakesoftware.GPUImage.cameraFrameProcessingQueue",
        attributes: [])
    
    public init(sessionPreset:AVCaptureSession.Preset, cameraDevice:AVCaptureDevice? = nil, captureAsYUV:Bool = true) throws {
        //self.location = location
        //self.orientation = orientation

        self.captureSession = AVCaptureSession()
        self.captureSession.beginConfiguration()
        
        self.captureAsYUV = captureAsYUV
        
        self.inputCamera = Camera.device()
        self.videoInput = try AVCaptureDeviceInput(device:inputCamera)
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        }
        
        // Add the video frame output
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = false
        
        if captureAsYUV {
            supportsFullYUVRange = true
            let (pipelineState, lookupTable) = generateRenderPipelineState(device:sharedMetalRenderingDevice, vertexFunctionName:"twoInputVertex", fragmentFunctionName:"yuvConversionFullRangeFragment", operationName:"YUVToRGB")
            self.yuvConversionRenderPipelineState = pipelineState
            self.yuvLookupTable = lookupTable
            videoOutput.videoSettings = [kCVPixelBufferMetalCompatibilityKey as String: true,
                                         kCVPixelBufferPixelFormatTypeKey as String:NSNumber(value:Int32(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange))]
        } else {
            self.yuvConversionRenderPipelineState = nil
        }

        if (captureSession.canAddOutput(videoOutput)) {
            captureSession.addOutput(videoOutput)
        }
        
        captureSession.sessionPreset = sessionPreset
        captureSession.commitConfiguration()
        
        super.init()
        
        let _ = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, sharedMetalRenderingDevice.device, nil, &videoTextureCache)

        videoOutput.setSampleBufferDelegate(self, queue:cameraProcessingQueue)
    }
    
    deinit {
        cameraFrameProcessingQueue.sync {
            self.stopCapture()
            self.videoOutput?.setSampleBufferDelegate(nil, queue:nil)
        }
    }
    
    static func device() -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for:AVMediaType.video)
        for case let device in devices {
            if (device.position == .back) {
                return device
            }
        }
        
        return AVCaptureDevice.default(for: AVMediaType.video)
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard (frameRenderingSemaphore.wait(timeout:DispatchTime.now()) == DispatchTimeoutResult.success) else { return }
        
        //let startTime = CFAbsoluteTimeGetCurrent()
        
        let cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let bufferWidth = CVPixelBufferGetWidth(cameraFrame)
        let bufferHeight = CVPixelBufferGetHeight(cameraFrame)
        let currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        CVPixelBufferLockBaseAddress(cameraFrame, CVPixelBufferLockFlags(rawValue:CVOptionFlags(0)))
        
        cameraFrameProcessingQueue.async {
            
            CVPixelBufferUnlockBaseAddress(cameraFrame, CVPixelBufferLockFlags(rawValue:CVOptionFlags(0)))
            
            var texture:Texture?
            if self.captureAsYUV {
                var luminanceTextureRef:CVMetalTexture? = nil
                var chrominanceTextureRef:CVMetalTexture? = nil
                // Luminance plane
                let _ = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.videoTextureCache!, cameraFrame, nil, .r8Unorm, bufferWidth, bufferHeight, 0, &luminanceTextureRef)
                // Chrominance plane
                let _ = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.videoTextureCache!, cameraFrame, nil, .rg8Unorm, bufferWidth / 2, bufferHeight / 2, 1, &chrominanceTextureRef)
                
                if let concreteLuminanceTextureRef = luminanceTextureRef, let concreteChrominanceTextureRef = chrominanceTextureRef,
                    let luminanceTexture = CVMetalTextureGetTexture(concreteLuminanceTextureRef), let chrominanceTexture = CVMetalTextureGetTexture(concreteChrominanceTextureRef) {
                    
                    let conversionMatrix:Matrix3x3
                    if (self.supportsFullYUVRange) {
                        conversionMatrix = colorConversionMatrix601FullRangeDefault
                    } else {
                        conversionMatrix = colorConversionMatrix601Default
                    }
                    
                    let outputWidth:Int
                    let outputHeight:Int
                    
                    outputWidth = bufferHeight
                    outputHeight = bufferWidth
                    
                    let outputTexture = Texture(device:sharedMetalRenderingDevice.device, orientation:.portrait, width:outputWidth, height:outputHeight, timingStyle: .stillImage)
                    
//                    let outputTexture = Texture(device:sharedMetalRenderingDevice.device, orientation:.portrait, width:outputWidth, height:outputHeight, timingStyle: .videoFrame(timestamp: Timestamp(currentTime)))
                    
                    convertYUVToRGB(pipelineState:self.yuvConversionRenderPipelineState!, lookupTable:self.yuvLookupTable,
                                    luminanceTexture:Texture(orientation: .landscapeLeft, texture:luminanceTexture),
                                    chrominanceTexture:Texture(orientation: .landscapeLeft, texture:chrominanceTexture),
                                    resultTexture:outputTexture, colorConversionMatrix:conversionMatrix)
                    texture = outputTexture
                } else {
                    texture = nil
                }
            }
            self.renderView.newTextureAvailable(texture!, fromSourceIndex: 0)
            self.frameRenderingSemaphore.signal()
        }
    }
    
    public func startCapture() {
        
        let _ = frameRenderingSemaphore.wait(timeout:DispatchTime.distantFuture)
        self.frameRenderingSemaphore.signal()
        
        if (!captureSession.isRunning) {
            captureSession.startRunning()
        }
    }
    
    public func stopCapture() {
        if (captureSession.isRunning) {
            let _ = frameRenderingSemaphore.wait(timeout:DispatchTime.distantFuture)
            
            captureSession.stopRunning()
            self.frameRenderingSemaphore.signal()
        }
    }
}
