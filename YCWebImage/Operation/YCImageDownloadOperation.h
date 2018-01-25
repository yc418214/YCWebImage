//
//  YCImageDownloadOperation.h
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/23.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YCImageDownloadOperation : NSOperation

- (instancetype)initWithDownloadTask:(NSURLSessionDataTask *)downloadTask;

@end
