//
//  YCImageDownloadOperation.m
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/23.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "YCImageDownloadOperation.h"

#import <UIKit/UIKit.h>
//header
#import "YCWebImageMacro.h"

@interface YCImageDownloadOperation ()

@property (weak, nonatomic) NSURLSessionDataTask *downloadTask;

@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;

@property (assign, nonatomic, getter = isInQueue) BOOL inQueue;

@end

@implementation YCImageDownloadOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)initWithDownloadTask:(NSURLSessionDataTask *)downloadTask {
    self = [super init];
    if (self) {
        _downloadTask = downloadTask;
    }
    return self;
}

#pragma mark - NSOperation

- (void)start {
    @synchronized (self) {
        if (self.isCancelled) {
            self.finished = YES;
            return;
        }
        self.inQueue = YES;
        
        UIApplication *application = [UIApplication sharedApplication];
        WEAKSELF
        self.backgroundTaskId = [application beginBackgroundTaskWithExpirationHandler:^{
            STRONGSELF
            if (strongSelf) {
                [strongSelf cancel];
                
                [application endBackgroundTask:strongSelf.backgroundTaskId];
                strongSelf.backgroundTaskId = UIBackgroundTaskInvalid;
            }
        }];
        
        [self.downloadTask resume];
        self.executing = YES;
        
        if (self.backgroundTaskId != UIBackgroundTaskInvalid) {
            [application endBackgroundTask:self.backgroundTaskId];
            self.backgroundTaskId = UIBackgroundTaskInvalid;
        }
    }
}

- (void)cancel {
    if (self.isFinished)  {
        return;
    }
    [super cancel];
    
    @synchronized (self) {
        if (self.downloadTask.state != NSURLSessionTaskStateCompleted) {
            [self.downloadTask cancel];
        }
        
        if (!self.isInQueue) {
            return;
        }
        self.executing = NO;
        self.finished = YES;
    }
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isConcurrent {
    return YES;
}

@end
