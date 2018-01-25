//
//  UIImageView+YCWebImage.h
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/24.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^YCWebImageProgressBlock)(CGFloat progress);

typedef void(^YCWebImageCompletionBlock)(UIImage *image, NSData *imageData);

@interface UIImageView (YCWebImage)

@property (assign, nonatomic) BOOL yc_showActivityIndicator;

@property (strong, nonatomic) UIActivityIndicatorView *yc_activityIndicatorView;

- (void)yc_setImageWithURL:(NSURL *)imageURL;

- (void)yc_setImageWithURL:(NSURL *)imageURL
          placeholderImage:(UIImage *)placeholderImage;

- (void)yc_setImageWithURL:(NSURL *)imageURL
          placeholderImage:(UIImage *)placeholderImage
           completionBlock:(YCWebImageCompletionBlock)completionBlock;

- (void)yc_setImageWithURL:(NSURL *)imageURL
          placeholderImage:(UIImage *)placeholderImage
             progressBlock:(YCWebImageProgressBlock)progressBlock
           completionBlock:(YCWebImageCompletionBlock)completionBlock;

- (void)yc_setImageWithURL:(NSURL *)imageURL
          placeholderImage:(UIImage *)placeholderImage
               failedImage:(UIImage *)failedImage
             progressBlock:(YCWebImageProgressBlock)progressBlock
           completionBlock:(YCWebImageCompletionBlock)completionBlock;

@end
