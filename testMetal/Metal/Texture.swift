import Foundation
import Metal
#if os(iOS)
import UIKit
#endif

public class Texture {
    public var orientation: ImageOrientation
    
    public let texture: MTLTexture
    
    public init(orientation: ImageOrientation, texture: MTLTexture) {
        self.orientation = orientation
        self.texture = texture
    }
}

extension Texture {
    func textureCoordinates(for outputOrientation:ImageOrientation, normalized:Bool) -> [Float] {
        let inputRotation = self.orientation.rotationNeeded(for:outputOrientation)

        let xLimit:Float
        let yLimit:Float
        if normalized {
            xLimit = 1.0
            yLimit = 1.0
        } else {
            xLimit = Float(self.texture.width)
            yLimit = Float(self.texture.height)
        }
        
        switch inputRotation {
        case .noRotation: return [0.0, 0.0, xLimit, 0.0, 0.0, yLimit, xLimit, yLimit]
        case .rotateCounterclockwise: return [0.0, yLimit, 0.0, 0.0, xLimit, yLimit, xLimit, 0.0]
        case .rotateClockwise: return [xLimit, 0.0, xLimit, yLimit, 0.0, 0.0, 0.0, yLimit]
        case .rotate180: return [xLimit, yLimit, 0.0, yLimit, xLimit, 0.0, 0.0, 0.0]
        case .flipHorizontally: return [xLimit, 0.0, 0.0, 0.0, xLimit, yLimit, 0.0, yLimit]
        case .flipVertically: return [0.0, yLimit, xLimit, yLimit, 0.0, 0.0, xLimit, 0.0]
        case .rotateClockwiseAndFlipVertically: return [0.0, 0.0, 0.0, yLimit, xLimit, 0.0, xLimit, yLimit]
        case .rotateClockwiseAndFlipHorizontally: return [xLimit, yLimit, xLimit, 0.0, 0.0, yLimit, 0.0, 0.0]
        }
    }
}
