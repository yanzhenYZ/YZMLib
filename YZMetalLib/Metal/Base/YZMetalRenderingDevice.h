//
//  YZMetalRenderingDevice.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/9.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@interface YZMetalRenderingDevice : NSObject
@property (nonatomic, strong, readonly) id<MTLDevice> device;


+ (instancetype)share;
@end


