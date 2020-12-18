//
//  Brightness.swift
//  testMetal
//
//  Created by 闫振 on 2020/12/18.
//

import UIKit
import Metal

class Brightness: NSObject {

    var brightness:Float = 0.0
    var renderViwe: RenderView?
    var renderPipelineState: MTLRenderPipelineState!
    override init() {
        super.init()
        generaPipelineState()
    }
    
    public func newTextureAvailable(_ texture:MTLTexture, fromSourceIndex:UInt) {
        guard let commandBuffer = sharedMetalRenderingDevice.commandQueue.makeCommandBuffer() else {return}

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                         width: texture.width,
                                                                         height: texture.height,
                                                                         mipmapped: false)
        textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        guard let newTexture = sharedMetalRenderingDevice.device.makeTexture(descriptor: textureDescriptor) else {
            fatalError("Could not create texture of size:")
        }

        renderQuad(commandBuffer: commandBuffer, texture:texture, outputTexture: newTexture)
        commandBuffer.commit()
        
        if YZBRIGHT {
            renderViwe?.newTextureAvailable(texture, fromSourceIndex: 0)
        }
    }
}

private extension Brightness {
    func generaPipelineState() {
        let vertexFunction = sharedMetalRenderingDevice.shaderLibrary.makeFunction(name: "oneInputVertex")
        let fragmentFunction = sharedMetalRenderingDevice.shaderLibrary.makeFunction(name: "brightnessFragment")
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
        descriptor.rasterSampleCount = 1
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        renderPipelineState = try? sharedMetalRenderingDevice.device.makeRenderPipelineState(descriptor: descriptor)
        
    }
    
    func renderQuad(commandBuffer:MTLCommandBuffer, texture:MTLTexture, outputTexture:MTLTexture) {
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
        
        //let input:[Float] = [0, 0, 1, 0, 0, 1, 1, 1]
        let input:[Float] = [0, 1, 0, 0, 1, 1, 1, 0]
        let textureBuffer = sharedMetalRenderingDevice.device.makeBuffer(bytes: input,
                                                                         length: input.count * MemoryLayout<Float>.size,
                                                                         options: [])!
        textureBuffer.label = "Texture Coordinates"
        
        renderEncoder.setVertexBuffer(textureBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentTexture(texture, index: 0)
    
        restoreShaderSettings(renderEncoder: renderEncoder)
        
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
    }
    
    func restoreShaderSettings(renderEncoder: MTLRenderCommandEncoder) {
        let f601:[Float] = [brightness]
            let uniformBuffer = sharedMetalRenderingDevice.device.makeBuffer(bytes: f601,
                                                                             length: f601.count * MemoryLayout<Float>.size,
                                                                             options: [])!
            renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 1)

    }
}
