//
//  YCImageIODecoder.h
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/23.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern BOOL YCImageRefContainsAlpha (CGImageRef imageRef);

@interface YCImageIODecoder : NSObject

@property (assign, nonatomic, readonly) UIImageOrientation imageOrientation;

@property (strong, nonatomic, readonly) UIImage *decodedImage;

+ (instancetype)decoderWithImageData:(NSData *)imageData scale:(CGFloat)scale;

+ (instancetype)decoderWithImage:(UIImage *)image;

+ (UIImageOrientation)imageOrientationWithImageSource:(CGImageSourceRef)imageSource;

@end
