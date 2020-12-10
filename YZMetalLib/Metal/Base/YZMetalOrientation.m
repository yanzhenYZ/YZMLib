//
//  YZMetalOrientation.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/10.
//

#import "YZMetalOrientation.h"

@implementation YZMetalOrientation
+ (BOOL)needRotation:(UIInterfaceOrientation)orientation width:(size_t)width height:(size_t)height {
    if ((UIInterfaceOrientationIsPortrait(orientation) && width > height)
        || (UIInterfaceOrientationIsLandscape(orientation) && width < height))
    {
        return YES;
    }
    return NO;
}
@end
