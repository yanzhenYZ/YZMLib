//
//  main.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/8.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

/**
 3.0.5 Metal 抽出对外工具类
 3.0.9 打包SDK
 */

/**iPhone6s 30fps
 BGRA：渲染没有美颜 55.3s ~~ 9.2%
 BGRA：渲染美颜    1.43m ~~ 14.3%
 */

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
