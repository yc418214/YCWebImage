//
//  YCWebImageMacro.h
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/24.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#ifndef YCWebImageMacro_h
#define YCWebImageMacro_h

#define WEAKSELF        __weak typeof(self) weakSelf = self;
#define STRONGSELF      typeof(self) strongSelf = weakSelf;

#define EXECUTE_START               NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
#define EXECUTE_END(fmt, ...)   \
NSLog((fmt @" execute time : %.3f s"), ##__VA_ARGS__, [[NSDate date] timeIntervalSince1970] - start); \

#endif /* YCWebImageMacro_h */
