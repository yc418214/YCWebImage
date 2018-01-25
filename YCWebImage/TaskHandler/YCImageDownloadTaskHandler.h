//
//  YCImageDownloadTaskHandler.h
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/23.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import <Foundation/Foundation.h>

//header
#import "YCWebImageBlock.h"

//use for removing callback
@interface YCImageDownloadTaskHandlerCallbackToken : NSObject
@end

typedef void(^YCImageDownloadTaskCompletionBlock)(void);

@interface YCImageDownloadTaskHandler : NSObject <NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

@property (strong, nonatomic, readonly) NSURLSessionDataTask *downloadTask;

@property (copy, nonatomic) YCImageDownloadTaskCompletionBlock completionBlock;

+ (instancetype)handlerWithRequest:(NSURLRequest *)imageURLRequest inSession:(NSURLSession *)session;

- (YCImageDownloadTaskHandlerCallbackToken *)addProgressBlock:(YCImageDownloadProgressBlock)progressBlock
                                              completionBlock:(YCImageDownloadCompletionBlock)completionBlock;

- (void)cancelDownloadWithCallbackToken:(YCImageDownloadTaskHandlerCallbackToken *)callbackToken;

- (void)cancelDownloadImmediately;

@end
