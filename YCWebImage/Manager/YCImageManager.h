//
//  YCImageManager.h
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/24.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//待扩展
typedef NS_OPTIONS(NSUInteger, YCImageManagerLoadImageOptions) {
    //if image is in memory cache, won't download
    YCImageManagerLoadImageShouldRefreshCache = 1 << 0,
    //decode image
    YCImageManagerLoadImageShouldDecode = 1 << 1
};

typedef void(^YCImageManagerLoadImageProgressBlock)(NSUInteger receivedLength, NSUInteger expectedLength, NSURL *imageURL);
typedef void(^YCImageManagerLoadImageCompletionBlock)(UIImage *image, NSData *imageData, NSURL *imageURL, NSError *error);

@interface YCImageLoadImageToken : NSObject
@end

@interface YCImageManager : NSObject

+ (instancetype)sharedManager;

- (YCImageLoadImageToken *)loadImageWithURL:(NSURL *)imageURL
                            completionBlock:(YCImageManagerLoadImageCompletionBlock)completionBlock;

- (YCImageLoadImageToken *)loadImageWithURL:(NSURL *)imageURL
                              progressBlock:(YCImageManagerLoadImageProgressBlock)progressBlock
                            completionBlock:(YCImageManagerLoadImageCompletionBlock)completionBlock;

- (YCImageLoadImageToken *)loadImageWithURL:(NSURL *)imageURL
                                    options:(YCImageManagerLoadImageOptions)options
                            completionBlock:(YCImageManagerLoadImageCompletionBlock)completionBlock;

- (YCImageLoadImageToken *)loadImageWithURL:(NSURL *)imageURL
                                    options:(YCImageManagerLoadImageOptions)options
                              progressBlock:(YCImageManagerLoadImageProgressBlock)progressBlock
                            completionBlock:(YCImageManagerLoadImageCompletionBlock)completionBlock;

- (void)cancelLoadingImageWithToken:(YCImageLoadImageToken *)token;

@end
