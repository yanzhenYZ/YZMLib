import Foundation
import MetalKit

public class RenderView: MTKView {
    var currentTexture: MTLTexture?
    var renderPipelineState:MTLRenderPipelineState!
    public override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: sharedMetalRenderingDevice.device)
        
        commonInit()
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    public func newTextureAvailable(_ texture:MTLTexture, fromSourceIndex:UInt) {
        self.drawableSize = CGSize(width: texture.width, height: texture.height)
        currentTexture = texture
        self.draw()
    }
    
    //使用代理避免重复调用
//    public override func draw(_ rect:CGRect) {
//        if let currentDrawable = self.currentDrawable {
//            let commandBuffer = sharedMetalRenderingDevice.commandQueue.makeCommandBuffer()
//
//            renderQuad(commandBuffer:commandBuffer!, outputTexture: currentDrawable.texture)
//
//            commandBuffer?.present(currentDrawable)
//            commandBuffer?.commit()
//        }
//    }
}

extension RenderView: MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("drawableSizeWillChange")
    }
    
    public func draw(in view: MTKView) {
        if let currentDrawable = view.currentDrawable {
            let commandBuffer = sharedMetalRenderingDevice.commandQueue.makeCommandBuffer()

            renderQuad(commandBuffer:commandBuffer!, outputTexture: currentDrawable.texture)

            commandBuffer?.present(currentDrawable)
            commandBuffer?.commit()
        }
    }
}


private extension RenderView {
    func renderQuad(commandBuffer:MTLCommandBuffer, outputTexture:MTLTexture) {
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
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass) else {
            fatalError("Could not create render encoder")
        }
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        let input:[Float] = [0, 0, 1, 0, 0, 1, 1, 1]
        let textureBuffer = sharedMetalRenderingDevice.device.makeBuffer(bytes: input,
                                                                         length: input.count * MemoryLayout<Float>.size,
                                                                         options: [])!
        textureBuffer.label = "Texture Coordinates"
        
        renderEncoder.setVertexBuffer(textureBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentTexture(currentTexture, index: 0)
        
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
    }
}

private extension RenderView {
    func commonInit() {
        framebufferOnly = false
        autoResizeDrawable = true
        
        self.device = sharedMetalRenderingDevice.device
        
        
        let vertexFunction = sharedMetalRenderingDevice.shaderLibrary.makeFunction(name: "oneInputVertex")
        let fragmentFunction = sharedMetalRenderingDevice.shaderLibrary.makeFunction(name: "passthroughFragment")
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
        descriptor.rasterSampleCount = 1
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        renderPipelineState = try? sharedMetalRenderingDevice.device.makeRenderPipelineState(descriptor: descriptor)

        self.backgroundColor = .red
        enableSetNeedsDisplay = false
        isPaused = true
        self.contentMode = .scaleAspectFit
        self.delegate = self
    }
}
