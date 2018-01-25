//
//  YCImageDownloader+NetworkActivityIndicator.m
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/25.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "YCImageDownloader+NetworkActivityIndicator.h"

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface YCImageDownloader ()

@property (assign, nonatomic) NSUInteger downloadTaskCount;

@property (strong, nonatomic) NSLock *downloadTaskCountLock;

@end

@implementation YCImageDownloader (NetworkActivityIndicator)

- (void)addDownloadTask {
    [self.downloadTaskCountLock lock];
    self.downloadTaskCount++;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    });
    [self.downloadTaskCountLock unlock];
}

- (void)downloadTaskDidFinish {
    [self.downloadTaskCountLock lock];
    self.downloadTaskCount--;
    self.downloadTaskCount = MAX(self.downloadTaskCount, 0);
    if (self.downloadTaskCount == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        });
    }
    [self.downloadTaskCountLock unlock];
}

- (void)removeAllDownloadTasks {
    [self.downloadTaskCountLock lock];
    self.downloadTaskCount = 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    });
    [self.downloadTaskCountLock unlock];
}

#pragma mark - getter

- (NSUInteger)downloadTaskCount {
    return [objc_getAssociatedObject(self, @selector(downloadTaskCount)) unsignedIntegerValue];
}

- (NSLock *)downloadTaskCountLock {
    NSLock *downloadTaskCountLock = objc_getAssociatedObject(self, @selector(downloadTaskCountLock));
    if (!downloadTaskCountLock) {
        downloadTaskCountLock = [[NSLock alloc] init];
        self.downloadTaskCountLock = downloadTaskCountLock;
    }
    return downloadTaskCountLock;
}

#pragma mark - setter

- (void)setDownloadTaskCount:(NSUInteger)downloadTaskCount {
    objc_setAssociatedObject(self,
                             @selector(downloadTaskCount),
                             @(downloadTaskCount),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setDownloadTaskCountLock:(NSLock *)downloadTaskCountLock {
    objc_setAssociatedObject(self,
                             @selector(downloadTaskCountLock),
                             downloadTaskCountLock,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
