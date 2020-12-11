//
//  YZMetalDevice.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/11.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@interface YZMetalDevice : NSObject
@property (nonatomic, strong, readonly) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLLibrary> defaultLibrary;

+ (instancetype)defaultDevice;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

@end

