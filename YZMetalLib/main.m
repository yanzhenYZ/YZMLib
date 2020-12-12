//
//  main.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/8.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

/**
 2.0.2 视频采集格式 
 2.0.3 使用matal数据格式
 2.0.4 前置后置摄像头
 2.0.5 旋转方向
 2.0.6 输出bgra buffer
 2.0.7 YZMTKView 显示模式问题
 */

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
