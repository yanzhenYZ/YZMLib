//
//  YZBrightness.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/19.
//

#import <Foundation/Foundation.h>
#import "YZMTKView.h"

@interface YZBrightness : NSObject
@property (nonatomic, assign) float brightness;
@property (nonatomic, strong) YZMTKView *view;
- (void)newTextureAvailable:(id<MTLTexture>)texture index:(NSInteger)index;

@end


