//
//  YCImageDownloader.h
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/23.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YCWebImageBlock.h"

typedef NSDictionary<NSString *, NSString *> YCImageDownloadHeadersDictionary;

//header config
typedef YCImageDownloadHeadersDictionary *(^YCImageDownloadHeadersConfigurationBlock)(NSURL *imageURL, NSDictionary *headers);

typedef NS_OPTIONS(NSUInteger, YCImageDownloaderDownloadOrder) {
    //first in first out
    YCImageDownloaderFIFODownloadOrder,
    //last in first out
    YCImageDownloaderLIFODownloadOrder
};

//use for cancelling download task
@interface YCImageDownloadToken : NSObject
@property (strong, nonatomic, readonly) NSURL *imageURL;
@end

@interface YCImageDownloader : NSObject

@property (assign, nonatomic) NSUInteger maxConcurrentDownloadCount;

@property (strong, nonatomic) NSURLCredential *URLCredential;

@property (assign, nonatomic) YCImageDownloaderDownloadOrder downloadOrder;

@property (copy, nonatomic) YCImageDownloadHeadersConfigurationBlock headersConfigurationBlock;

+ (instancetype)sharedDownloader;

- (YCImageDownloadToken *)downloadImageWithURL:(NSURL *)imageURL
                                 progressBlock:(YCImageDownloadProgressBlock)progressBlock
                               completionBlock:(YCImageDownloadCompletionBlock)completionBlock;

- (void)cancelDownloadWithToken:(YCImageDownloadToken *)downloadToken;

- (void)cancelAllDownloads;

@end
