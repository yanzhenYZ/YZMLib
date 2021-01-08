//
//  YZBrightness.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/19.
//

#import <Foundation/Foundation.h>
#import "YZMTKView.h"

@interface YZBrightness : NSObject
/** default is YES */
@property (nonatomic, assign) BOOL enable;
/** default is 0.5 */
@property (nonatomic, assign) float beautyLevel;
/** default is 0.5 */
@property (nonatomic, assign) float brightLevel;

@property (nonatomic, strong) id<YZFilterProtocol> render;

- (void)newTextureAvailable:(id<MTLTexture>)texture index:(NSInteger)index;

@end


