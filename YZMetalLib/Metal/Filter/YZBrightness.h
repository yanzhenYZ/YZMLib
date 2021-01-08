//
//  YZBrightness.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/19.
//

#import "YZMetalFilter.h"

@interface YZBrightness : YZMetalFilter
/** default is YES */
@property (nonatomic, assign) BOOL enable;
/** default is 0.5 */
@property (nonatomic, assign) float beautyLevel;
/** default is 0.5 */
@property (nonatomic, assign) float brightLevel;

@end


