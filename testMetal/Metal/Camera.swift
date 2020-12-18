import Foundation
import AVFoundation
import Metal

//public class Camera: NSObject, ImageSource, AVCaptureVideoDataOutputSampleBufferDelegate {
public class Camera: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    var bright: Brightness?
    public var renderView: RenderView?
    public let captureSession:AVCaptureSession
    public let inputCamera:AVCaptureDevice!
    let videoInput:AVCaptureDeviceInput!
    let videoOutput:AVCaptureVideoDataOutput!
    var videoTextureCache: CVMetalTextureCache?
    
    var supportsFullYUVRange:Bool = false
    let captureAsYUV:Bool
    let yuvConversionRenderPipelineState:MTLRenderPipelineState?
    
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
            let vertexFunction = sharedMetalRenderingDevice.shaderLibrary.makeFunction(name: "twoInputVertex")
            let fragmentFunction = sharedMetalRenderingDevice.shaderLibrary.makeFunction(name: "yuvConversionFullRangeFragment")
            
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
            descriptor.rasterSampleCount = 1
            descriptor.vertexFunction = vertexFunction
            descriptor.fragmentFunction = fragmentFunction
            self.yuvConversionRenderPipelineState = try? sharedMetalRenderingDevice.device.makeRenderPipelineState(descriptor: descriptor)
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
    
    deinit {
        cameraFrameProcessingQueue.sync {
            self.stopCapture()
            self.videoOutput?.setSampleBufferDelegate(nil, queue:nil)
        }
    }
    
    static func device() -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for:AVMediaType.video)
        for case let device in devices {
            if (device.position == .front) {
                return device
            }
        }
        
        return AVCaptureDevice.default(for: AVMediaType.video)
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard (frameRenderingSemaphore.wait(timeout:DispatchTime.now()) == DispatchTimeoutResult.success) else { return }
        //let startTime = CFAbsoluteTimeGetCurrent()
        //let currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        cameraFrameProcessingQueue.async {
            self.processSampleBuffer(sampleBuffer);
         
        }
    }
    
    
}

private extension Camera {
    func processSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        let cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let bufferWidth = CVPixelBufferGetWidth(cameraFrame)
        let bufferHeight = CVPixelBufferGetHeight(cameraFrame)
        
        var luminanceTextureRef:CVMetalTexture? = nil
        var chrominanceTextureRef:CVMetalTexture? = nil
        // Luminance plane
        let _ = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.videoTextureCache!, cameraFrame, nil, .r8Unorm, bufferWidth, bufferHeight, 0, &luminanceTextureRef)
        // Chrominance plane
        let _ = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.videoTextureCache!, cameraFrame, nil, .rg8Unorm, bufferWidth / 2, bufferHeight / 2, 1, &chrominanceTextureRef)
        
        if let concreteLuminanceTextureRef = luminanceTextureRef, let concreteChrominanceTextureRef = chrominanceTextureRef,
            let luminanceTexture = CVMetalTextureGetTexture(concreteLuminanceTextureRef), let chrominanceTexture = CVMetalTextureGetTexture(concreteChrominanceTextureRef) {
            
            
            
            let outputWidth = bufferHeight
            let outputHeight = bufferWidth
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                             width: outputWidth,
                                                                             height: outputHeight,
                                                                             mipmapped: false)
            textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
            
            let newTexture = sharedMetalRenderingDevice.device.makeTexture(descriptor: textureDescriptor)
            convertYUVToRGB(luminanceTexture:luminanceTexture, chrominanceTexture:chrominanceTexture,
                            resultTexture:newTexture!)
            if YZBRIGHT {
                bright?.newTextureAvailable(newTexture!, fromSourceIndex: 0)
            } else {
                self.renderView?.newTextureAvailable(newTexture!, fromSourceIndex: 0)
            }
            //
            
            
            self.frameRenderingSemaphore.signal()
        }
        
    }
    
    func convertYUVToRGB(luminanceTexture:MTLTexture, chrominanceTexture:MTLTexture, resultTexture:MTLTexture) {
        
        guard let commandBuffer = sharedMetalRenderingDevice.commandQueue.makeCommandBuffer() else {return}

        renderQuad(buffer:commandBuffer, outputTexture:resultTexture, yTexture: luminanceTexture, uvTexture: chrominanceTexture)
        
        commandBuffer.commit()
    }
    //, inputTextures:[UInt:Texture]
    func renderQuad(buffer:MTLCommandBuffer, outputTexture:MTLTexture, yTexture:MTLTexture, uvTexture: MTLTexture) {
        let imageVertices:[Float] = [-1.0, 1.0, 1.0, 1.0, -1.0, -1.0, 1.0, -1.0]
        let vertexBuffer = sharedMetalRenderingDevice.device.makeBuffer(bytes: imageVertices,
                                                                        length: imageVertices.count * MemoryLayout<Float>.size,
                                                                        options: [])!
        vertexBuffer.label = "Vertices"
        
        //print(imageVertices.count * MemoryLayout<Float>.size, 111222)
        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = outputTexture
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1)
        renderPass.colorAttachments[0].storeAction = .store
        renderPass.colorAttachments[0].loadAction = .clear
        
        guard let renderEncoder = buffer.makeRenderCommandEncoder(descriptor: renderPass) else {
            fatalError("Could not create render encoder")
        }
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setRenderPipelineState(self.yuvConversionRenderPipelineState!)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        //uv
        var currentTexture = yTexture
        let input:[Float] = [0, 1, 0, 0, 1, 1, 1, 0]
        let textureBuffer = sharedMetalRenderingDevice.device.makeBuffer(bytes: input,
                                                                         length: input.count * MemoryLayout<Float>.size,
                                                                         options: [])!
        textureBuffer.label = "Texture Coordinates"
        
        renderEncoder.setVertexBuffer(textureBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentTexture(currentTexture, index: 0)
        
        
        currentTexture = uvTexture
        let textureBufferUV = sharedMetalRenderingDevice.device.makeBuffer(bytes: input,
                                                                         length: input.count * MemoryLayout<Float>.size,
                                                                         options: [])!
        textureBuffer.label = "Texture Coordinates"
        renderEncoder.setVertexBuffer(textureBufferUV, offset: 0, index: 2)
        renderEncoder.setFragmentTexture(currentTexture, index: 1)

        restoreShaderSettings(renderEncoder: renderEncoder)
        
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
    }
    
    

    func restoreShaderSettings(renderEncoder: MTLRenderCommandEncoder) {
        let f601:[Float] = [1, 1, 1, 0, 0, 0.343, 1.765, 0, 1.4, -0.711, 0, 0]
            let uniformBuffer = sharedMetalRenderingDevice.device.makeBuffer(bytes: f601,
                                                                             length: f601.count * MemoryLayout<Float>.size,
                                                                             options: [])!
            renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 1)

    }
}
