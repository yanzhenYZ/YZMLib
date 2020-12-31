//
//  main.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/8.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

/**
 
 2.0.7 打包SDK
 2.0.9 全部代码 - 属性设置 - metal语言
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
