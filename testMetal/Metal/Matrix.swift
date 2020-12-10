import QuartzCore



public struct Matrix3x3 {
    public let m11:Float, m12:Float, m13:Float
    public let m21:Float, m22:Float, m23:Float
    public let m31:Float, m32:Float, m33:Float
    
    public init(rowMajorValues:[Float]) {
        guard rowMajorValues.count > 8 else { fatalError("Tried to initialize a 3x3 matrix with fewer than 9 values") }
        
        self.m11 = rowMajorValues[0]
        self.m12 = rowMajorValues[1]
        self.m13 = rowMajorValues[2]
        
        self.m21 = rowMajorValues[3]
        self.m22 = rowMajorValues[4]
        self.m23 = rowMajorValues[5]
        
        self.m31 = rowMajorValues[6]
        self.m32 = rowMajorValues[7]
        self.m33 = rowMajorValues[8]
    }
    
    public static let identity = Matrix3x3(rowMajorValues:[1.0, 0.0, 0.0,
                                                           0.0, 1.0, 0.0,
                                                           0.0, 0.0, 1.0])
    
    public static let centerOnly = Matrix3x3(rowMajorValues:[0.0, 0.0, 0.0,
                                                             0.0, 1.0, 0.0,
                                                             0.0, 0.0, 0.0])
}


