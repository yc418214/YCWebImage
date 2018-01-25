//
//  YCWebImageProgressViewProtocol.h
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/24.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#ifndef YCWebImageProgressViewProtocol_h
#define YCWebImageProgressViewProtocol_h

@protocol YCWebImageProgressViewProtocol <NSObject>

@required
- (void)updateProgress:(CGFloat)progress;

@end

#endif /* YCWebImageProgressViewProtocol_h */
