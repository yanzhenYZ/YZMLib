//
//  YZCamera.h
//  YZMetalLib
//
//  Created by 闫振 on 2020/12/11.
//

#import <Foundation/Foundation.h>
#import "YZMTKView.h"

@interface YZCamera : NSObject
@property (nonatomic, strong) YZMTKView *view;

- (void)startRunning;
- (void)stopRunning;
@end


