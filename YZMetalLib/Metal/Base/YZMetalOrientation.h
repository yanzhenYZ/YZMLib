//
//  YZMetalOrientation.h
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/10.
//

#import <UIKit/UIKit.h>

@interface YZMetalOrientation : NSObject

+ (BOOL)needRotation:(UIInterfaceOrientation)orientation width:(size_t)width height:(size_t)height;

@end

