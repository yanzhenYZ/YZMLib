//
//  Brightness.swift
//  testMetal
//
//  Created by 闫振 on 2020/12/18.
//

import UIKit
import Metal

class Brightness: NSObject {

    var renderViwe: RenderView?
    var renderPipelineState: MTLRenderPipelineState!
    override init() {
        super.init()
        generaPipelineState()
    }
    
    public func newTextureAvailable(_ texture:MTLTexture, fromSourceIndex:UInt) {
        print(1234, texture.width, texture.height)
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
}
