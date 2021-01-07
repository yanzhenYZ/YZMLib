//
//  main.m
//  YZMetalLib
//
//  Created by yanzhen on 2020/12/8.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

/**
 
 3.0.1 输出分辨率问题
 3.0.2 filter协议类封装
 3.0.3 Metal 抽出对外工具类
 3.0.4 摄像头操作
 
 3.0.6 打包SDK
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
