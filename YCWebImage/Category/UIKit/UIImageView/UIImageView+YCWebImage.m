//
//  UIImageView+YCWebImage.m
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/24.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "UIImageView+YCWebImage.h"

#import <objc/runtime.h>
//manager
#import "YCImageManager.h"
//header
#import "YCWebImageProgressViewProtocol.h"

@interface UIImageView ()

@property (strong, nonatomic) YCImageLoadImageToken *yc_currentLoadImageToken;

@end

@implementation UIImageView (YCWebImage)

- (void)yc_setImageWithURL:(NSURL *)imageURL {
    [self yc_setImageWithURL:imageURL
            placeholderImage:nil
                 failedImage:nil
               progressBlock:nil
             completionBlock:nil];
}

- (void)yc_setImageWithURL:(NSURL *)imageURL
          placeholderImage:(UIImage *)placeholderImage {
    [self yc_setImageWithURL:imageURL
            placeholderImage:placeholderImage
                 failedImage:nil
               progressBlock:nil
             completionBlock:nil];
}

- (void)yc_setImageWithURL:(NSURL *)imageURL
          placeholderImage:(UIImage *)placeholderImage
           completionBlock:(YCWebImageCompletionBlock)completionBlock {
    [self yc_setImageWithURL:imageURL
            placeholderImage:placeholderImage
                 failedImage:nil
               progressBlock:nil
             completionBlock:completionBlock];
}

- (void)yc_setImageWithURL:(NSURL *)imageURL
          placeholderImage:(UIImage *)placeholderImage
             progressBlock:(YCWebImageProgressBlock)progressBlock
           completionBlock:(YCWebImageCompletionBlock)completionBlock {
    [self yc_setImageWithURL:imageURL
            placeholderImage:placeholderImage
                 failedImage:nil
               progressBlock:progressBlock
             completionBlock:completionBlock];
}

- (void)yc_setImageWithURL:(NSURL *)imageURL
          placeholderImage:(UIImage *)placeholderImage
               failedImage:(UIImage *)failedImage
             progressBlock:(YCWebImageProgressBlock)progressBlock
           completionBlock:(YCWebImageCompletionBlock)completionBlock {
    self.image = placeholderImage;
    
    // cancel previous load image action
    YCImageManager *imageManager = [YCImageManager sharedManager];
    [imageManager cancelLoadingImageWithToken:self.yc_currentLoadImageToken];
    
    if (self.yc_showActivityIndicator) {
        [self yc_showActivityIndicatorView];
    }
    
    YCImageManagerLoadImageProgressBlock loadImageProgressBlock = ^(NSUInteger receivedLength, NSUInteger expectedLength, NSURL *imageURL) {
        CGFloat progress = (CGFloat)receivedLength / (CGFloat)expectedLength;
        if (progressBlock) {
            progressBlock(progress);
        }
    };
    YCImageManagerLoadImageCompletionBlock loadImageCompletionBlock = ^(UIImage *image, NSData *imageData, NSURL *imageURL, NSError *error) {
        self.yc_currentLoadImageToken = nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.image = image ? : (failedImage ? : placeholderImage);
            
            if (completionBlock) {
                completionBlock(image, imageData);
            }
            
            if (self.yc_showActivityIndicator) {
                [self yc_hideActivityIndicatorView];
            }
        });
    };
    YCImageManagerLoadImageOptions options = YCImageManagerLoadImageShouldDecode;
    YCImageLoadImageToken *loadImageToken = [imageManager loadImageWithURL:imageURL
                                                                   options:options
                                                             progressBlock:loadImageProgressBlock
                                                           completionBlock:loadImageCompletionBlock];
    self.yc_currentLoadImageToken = loadImageToken;
}

#pragma mark - private methods

- (void)yc_showActivityIndicatorView {
    if (self.yc_activityIndicatorView.superview == self) {
        return;
    }
    if (!self.yc_activityIndicatorView) {
        self.yc_activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self addSubview:self.yc_activityIndicatorView];
        [self yc_setupConstraintWithSubview:self.yc_activityIndicatorView];
    }
    [self.yc_activityIndicatorView startAnimating];
}

- (void)yc_hideActivityIndicatorView {
    if (self.yc_activityIndicatorView) {
        [self.yc_activityIndicatorView removeFromSuperview];
        self.yc_activityIndicatorView = nil;
    }
}

- (void)yc_setupConstraintWithSubview:(UIView *)subview {
    subview.translatesAutoresizingMaskIntoConstraints = NO;
    [self addConstraint:[NSLayoutConstraint constraintWithItem:subview
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1
                                                      constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:subview
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1
                                                      constant:0]];
}

#pragma mark - getter

- (BOOL)yc_showActivityIndicator {
    return [objc_getAssociatedObject(self, @selector(yc_showActivityIndicator)) boolValue];
}

- (UIActivityIndicatorView *)yc_activityIndicatorView {
    return objc_getAssociatedObject(self, @selector(yc_activityIndicatorView));
}

- (YCImageLoadImageToken *)yc_currentLoadImageToken {
    return objc_getAssociatedObject(self, @selector(yc_currentLoadImageToken));
}

#pragma mark - setter

- (void)setYc_showActivityIndicator:(BOOL)yc_showActivityIndicator {
    objc_setAssociatedObject(self,
                             @selector(yc_showActivityIndicator),
                             @(yc_showActivityIndicator),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setYc_activityIndicatorView:(UIActivityIndicatorView *)yc_activityIndicatorView {
    objc_setAssociatedObject(self,
                             @selector(yc_activityIndicatorView),
                             yc_activityIndicatorView,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setYc_currentLoadImageToken:(YCImageLoadImageToken *)yc_currentLoadImageToken {
    objc_setAssociatedObject(self,
                             @selector(yc_currentLoadImageToken),
                             yc_currentLoadImageToken,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
