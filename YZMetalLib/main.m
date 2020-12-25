//
//  main.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/8.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

/**
 2.0.1 前置后置摄像头
 2.0.2 镜像问题
 2.0.3 YZMTKView 显示模式问题
 
 2.0.7 美颜
 2.0.8 性能对比 GPU
 2.0.9 dealloc
 */

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
