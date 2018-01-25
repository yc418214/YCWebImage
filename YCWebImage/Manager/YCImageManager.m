//
//  YCImageManager.m
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/24.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "YCImageManager.h"

#import <pthread/pthread.h>
//header
#import "YCWebImageMacro.h"
//downloader
#import "YCImageDownloader.h"
//cache
#import "YCImageCache.h"
//manager
#import "YCFailedImageURLManager.h"
//category
#import "NSString+YCWebImage.h"
#import "UIImage+YCWebImage.h"
#import "NSError+YCWebImage.h"

@interface YCImageLoadImageToken ()
@property (strong, nonatomic) YCImageDownloadToken *downloadToken;
@property (assign, nonatomic, getter = isCancelled) BOOL cancelled;
+ (instancetype)token;
@end

@interface YCImageManager ()

@property (strong, nonatomic) YCImageCache *imageCache;

@property (strong, nonatomic) YCImageDownloader *imageDownloader;

@end

@implementation YCImageManager

+ (instancetype)sharedManager {
    static YCImageManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[YCImageManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _imageCache = [YCImageCache sharedImageCache];
        _imageDownloader = [YCImageDownloader sharedDownloader];
    }
    return self;
}

#pragma mark - public methods

- (YCImageLoadImageToken *)loadImageWithURL:(NSURL *)imageURL
                            completionBlock:(YCImageManagerLoadImageCompletionBlock)completionBlock {
    return [self loadImageWithURL:imageURL
                          options:0
                    progressBlock:nil
                  completionBlock:completionBlock];
}

- (YCImageLoadImageToken *)loadImageWithURL:(NSURL *)imageURL
                              progressBlock:(YCImageManagerLoadImageProgressBlock)progressBlock
                            completionBlock:(YCImageManagerLoadImageCompletionBlock)completionBlock {
    return [self loadImageWithURL:imageURL
                          options:0
                    progressBlock:progressBlock
                  completionBlock:completionBlock];
}

- (YCImageLoadImageToken *)loadImageWithURL:(NSURL *)imageURL
                                    options:(YCImageManagerLoadImageOptions)options
                            completionBlock:(YCImageManagerLoadImageCompletionBlock)completionBlock {
    return [self loadImageWithURL:imageURL
                          options:options
                    progressBlock:nil
                  completionBlock:completionBlock];
}

- (YCImageLoadImageToken *)loadImageWithURL:(NSURL *)imageURL
                                    options:(YCImageManagerLoadImageOptions)options
                              progressBlock:(YCImageManagerLoadImageProgressBlock)progressBlock
                            completionBlock:(YCImageManagerLoadImageCompletionBlock)completionBlock {
    __block YCImageLoadImageToken *loadImageToken = [YCImageLoadImageToken token];
    
    dispatch_block_t loadImageAction = ^{
#define RETURN_IF_LOAD_IMAGE_CANCELLED  \
if (loadImageToken.isCancelled) {   \
    return; \
}   \

        RETURN_IF_LOAD_IMAGE_CANCELLED;
        
        NSString *imageKey = [self imageKeyFromURL:imageURL];
        BOOL shouldDecode = options & YCImageManagerLoadImageShouldDecode;
        UIImage *image = [self.imageCache imageForKey:imageKey shouldDecode:shouldDecode];
        
        RETURN_IF_LOAD_IMAGE_CANCELLED;
        
        if (image) {
            [self executeLoadImageCompletionBlock:completionBlock
                                            image:image
                                        imageData:nil
                                         imageURL:imageURL
                                            error:NULL];
        }
        BOOL shouldRefreshCache = options & YCImageManagerLoadImageShouldRefreshCache;
        if (image && !shouldRefreshCache) {
            // no need to download
            return;
        }
        [self downloadImageWithURL:imageURL
                           options:options
                    loadImageToken:loadImageToken
                     progressBlock:progressBlock
                   completionBlock:completionBlock];
    };
    dispatch_async(dispatch_get_global_queue(0, 0), loadImageAction);
    
    return loadImageToken;
}

- (void)cancelLoadingImageWithToken:(YCImageLoadImageToken *)token {
    if (!token) {
        return;
    }
    token.cancelled = YES;
    [self.imageDownloader cancelDownloadWithToken:token.downloadToken];
}

#pragma mark - private methods

- (NSString *)imageKeyFromURL:(NSURL *)imageURL {
    return [imageURL.absoluteString yc_md5String];
}

- (void)downloadImageWithURL:(NSURL *)imageURL
                     options:(YCImageManagerLoadImageOptions)options
              loadImageToken:(YCImageLoadImageToken *)loadImageToken
               progressBlock:(YCImageManagerLoadImageProgressBlock)progressBlock
             completionBlock:(YCImageManagerLoadImageCompletionBlock)completionBlock {
    //handle failed URL
    YCFailedImageURLManager *failedImageURLManager = [YCFailedImageURLManager sharedManager];
    if (![failedImageURLManager shouldDownloadForImageURL:imageURL]) {
        NSError *error = [NSError yc_errorWithImageDownloadErrorCode:YCImageDownloadErrorCodeFailedURL];
        [self executeLoadImageCompletionBlock:completionBlock
                                        image:nil
                                    imageData:nil
                                     imageURL:imageURL
                                        error:error];
        return;
    }
    
    WEAKSELF
    YCImageDownloadCompletionBlock downloadCompletionBlock = ^(UIImage *image, NSData *imageData, BOOL isCancelled, NSError *error) {
        STRONGSELF
        
        if (isCancelled) {
            return;
        }
        if (!image) {
            if ([strongSelf shouldMarkFailedURLWithError:error]) {
                [failedImageURLManager markImageURLFailedWithURL:imageURL];
            }
        } else {
            //save image
            NSString *imageKey = [strongSelf imageKeyFromURL:imageURL];
            BOOL shouldDecode = options & YCImageManagerLoadImageShouldDecode;
            image = shouldDecode ? [image yc_decodedImage] : image;
            
            [strongSelf.imageCache saveImageInMemory:image forKey:imageKey isDecoded:shouldDecode];
            [strongSelf.imageCache saveImageDataInDisk:imageData forKey:imageKey];
        }
        [strongSelf executeLoadImageCompletionBlock:completionBlock
                                              image:image
                                          imageData:imageData
                                           imageURL:imageURL
                                              error:error];
    };
    YCImageDownloadProgressBlock downloadProgressBlock = ^(NSUInteger receivedLength, NSUInteger expectedLength, NSURL *imageURL) {
        if (progressBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
               progressBlock(receivedLength, expectedLength, imageURL);
            });
        }
    };
    YCImageDownloadToken *downloadToken = [self.imageDownloader downloadImageWithURL:imageURL
                                                                       progressBlock:downloadProgressBlock
                                                                     completionBlock:downloadCompletionBlock];
    loadImageToken.downloadToken = downloadToken;
}

- (void)executeLoadImageCompletionBlock:(YCImageManagerLoadImageCompletionBlock)completionBlock
                                  image:(UIImage *)image
                              imageData:(NSData *)imageData
                               imageURL:(NSURL *)imageURL
                                  error:(NSError *)error {
    if (!completionBlock) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        completionBlock(image, imageData, imageURL, error);
    });
}

- (BOOL)shouldMarkFailedURLWithError:(NSError *)error {
    return (error.code != NSURLErrorNotConnectedToInternet &&
            error.code != NSURLErrorCancelled &&
            error.code != NSURLErrorTimedOut &&
            error.code != NSURLErrorInternationalRoamingOff &&
            error.code != NSURLErrorDataNotAllowed &&
            error.code != NSURLErrorCannotFindHost &&
            error.code != NSURLErrorCannotConnectToHost &&
            error.code != NSURLErrorNetworkConnectionLost);
}

@end

@implementation YCImageLoadImageToken

+ (instancetype)token {
    YCImageLoadImageToken *token = [[YCImageLoadImageToken alloc] init];
    return token;
}

@end
