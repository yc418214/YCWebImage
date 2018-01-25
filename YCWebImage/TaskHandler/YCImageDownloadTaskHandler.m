//
//  YCImageDownloadTaskHandler.m
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/23.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "YCImageDownloadTaskHandler.h"

#import <UIKit/UIKit.h>
//category
#import "NSError+YCWebImage.h"
#import "NSData+YCWebImage.h"

static NSString * const kProgressCallbackKey = @"kProgressCallbackKey";
static NSString * const kCompletionCallbackKey = @"kCompletionCallbackKey";

@interface YCImageDownloadTaskHandlerCallbackToken ()
@property (copy, nonatomic) YCImageDownloadProgressBlock progressBlock;
@property (copy, nonatomic) YCImageDownloadCompletionBlock completionBlock;
+ (instancetype)callbackTokenWithProgressBlock:(YCImageDownloadProgressBlock)progressBlock
                               completionBlock:(YCImageDownloadCompletionBlock)completionBlock;
@end

@interface YCImageDownloadTaskHandler ()

@property (strong, nonatomic, readwrite) NSURLSessionDataTask *downloadTask;

@property (copy, nonatomic) NSURLRequest *imageURLRequest;

@property (strong, nonatomic) NSMutableArray *callbackTokensArray;

@property (assign, nonatomic) NSInteger expectedLength;

@property (strong, nonatomic) NSMutableData *imageData;

@property (assign, nonatomic, getter = isCancelled) BOOL cancelled;

@end

@implementation YCImageDownloadTaskHandler

+ (instancetype)handlerWithRequest:(NSURLRequest *)imageURLRequest inSession:(NSURLSession *)session {
    return [[self alloc] initWithRequest:imageURLRequest inSession:session];
}

- (instancetype)initWithRequest:(NSURLRequest *)imageURLRequest inSession:(NSURLSession *)session {
    self = [super init];
    if (self) {
        _imageURLRequest = [imageURLRequest copy];
        _callbackTokensArray = [NSMutableArray array];
        
        _downloadTask = [session dataTaskWithRequest:imageURLRequest];
    }
    return self;
}

#pragma mark - public methods

- (YCImageDownloadTaskHandlerCallbackToken *)addProgressBlock:(YCImageDownloadProgressBlock)progressBlock
                                              completionBlock:(YCImageDownloadCompletionBlock)completionBlock {
    YCImageDownloadTaskHandlerCallbackToken *callbackToken;
    @synchronized (self.callbackTokensArray) {
        callbackToken = [YCImageDownloadTaskHandlerCallbackToken callbackTokenWithProgressBlock:progressBlock
                                                                                completionBlock:completionBlock];
        [self.callbackTokensArray addObject:callbackToken];
    }
    return callbackToken;
}

- (void)cancelDownloadWithCallbackToken:(YCImageDownloadTaskHandlerCallbackToken *)callbackToken {
    @synchronized (self.callbackTokensArray) {
        [self.callbackTokensArray removeObjectIdenticalTo:callbackToken];
        if (self.callbackTokensArray.count == 0) {
            [self cancelDownloadTask];
        }
    }
}

- (void)cancelDownloadImmediately {
    @synchronized (self.callbackTokensArray) {
        [self.callbackTokensArray removeAllObjects];
        [self cancelDownloadTask];
    }
}

#pragma mark - private methods

- (void)cancelDownloadTask {
    self.cancelled = YES;
    [self executeCompletionCallbackWithError:[NSError yc_errorWithImageDownloadErrorCode:YCImageDownloadErrorCodeDownloadCancelled]];
}

- (void)executeCompletionBlock {
    YCImageDownloadTaskCompletionBlock completionBlock = self.completionBlock;
    if (completionBlock) {
        completionBlock();
        self.completionBlock = nil;
    }
}

- (void)executeProgressCallback {
    @synchronized (self.callbackTokensArray) {
        for (YCImageDownloadTaskHandlerCallbackToken *token in self.callbackTokensArray) {
            YCImageDownloadProgressBlock block = token.progressBlock;
            if (block) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block(self.imageData.length, self.expectedLength, self.imageURLRequest.URL);
                });
            }
        }
    }
}

- (void)executeCompletionCallbackWithError:(NSError *)error {
    [self executeCompletionCallbackWithImage:nil imageData:nil error:error];
}

- (void)executeCompletionCallbackWithImage:(UIImage *)image imageData:(NSData *)imageData error:(NSError *)error {
    @synchronized (self.callbackTokensArray) {
        for (YCImageDownloadTaskHandlerCallbackToken *token in self.callbackTokensArray) {
            YCImageDownloadCompletionBlock block = token.completionBlock;
            if (block) {
                block(image, imageData, self.isCancelled, error);
            }
        }
    }
    [self executeCompletionBlock];
}

#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    BOOL hasStatusCode = [response respondsToSelector:@selector(statusCode)];
    NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
    
    // 304 not modified
    if (hasStatusCode && (statusCode >= 400 || statusCode == 304)) {
        [self cancelDownloadImmediately];
    } else {
        NSInteger expectedLength = MAX(response.expectedContentLength, 0);
        self.imageData = [NSMutableData dataWithCapacity:expectedLength];
        self.expectedLength = expectedLength;
        
        [self executeProgressCallback];
    }
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.imageData appendData:data];
    
    [self executeProgressCallback];
}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (self.isCancelled) {
        return;
    }
    UIImage *image;
    NSError *downloadError;
    
    NSData *imageData = [self.imageData copy];
    BOOL emptyImageData = (!imageData || imageData.length == 0);
    
    if (!error && !emptyImageData) {
        YCImageType imageType = [imageData yc_imageType];
        if (imageType == YCImageTypeGIF) {
            //not support yet
        } else if (imageType == YCImageTypeWEBP) {
            //not support yet
        } else {
            image = [UIImage imageWithData:imageData];
        }
        if (!CGSizeEqualToSize(image.size, CGSizeZero)) {
            [self executeCompletionCallbackWithImage:image imageData:imageData error:NULL];
            return;
        }
        downloadError = [NSError yc_errorWithImageDownloadErrorCode:YCImageDownloadErrorCodeWithoutPixel];
    }
    downloadError = downloadError ? :
    (error ? : [NSError yc_errorWithImageDownloadErrorCode:YCImageDownloadErrorCodeEmptyImageData]);
    [self executeCompletionCallbackWithError:downloadError];
}

@end

#pragma mark - YCImageDownloadTaskHandlerCallbackToken

@implementation YCImageDownloadTaskHandlerCallbackToken
+ (instancetype)callbackTokenWithProgressBlock:(YCImageDownloadProgressBlock)progressBlock completionBlock:(YCImageDownloadCompletionBlock)completionBlock {
    YCImageDownloadTaskHandlerCallbackToken *callbackToken = [[YCImageDownloadTaskHandlerCallbackToken alloc] init];
    callbackToken.progressBlock = progressBlock;
    callbackToken.completionBlock = completionBlock;
    return callbackToken;
}
@end
