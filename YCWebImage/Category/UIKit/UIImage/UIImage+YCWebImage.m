//
//  UIImage+YCWebImage.m
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/23.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "UIImage+YCWebImage.h"

#import "YCImageIODecoder.h"

@implementation UIImage (YCWebImage)

+ (instancetype)yc_decodedImageWithData:(NSData *)data {
    if (!data || data.length == 0) {
        return nil;
    }
    __block UIImage *decodedImage;
    @autoreleasepool {
        YCImageIODecoder *imageDecoder = [YCImageIODecoder decoderWithImageData:data scale:1];
        decodedImage = imageDecoder.decodedImage;
    }
    return decodedImage;
}

- (instancetype)yc_decodedImage {
    __block UIImage *decodedImage;
    @autoreleasepool {
        YCImageIODecoder *imageDecoder = [YCImageIODecoder decoderWithImage:self];
        decodedImage = imageDecoder.decodedImage;
    }
    return decodedImage;
}

- (NSUInteger)yc_memoryCost {
    CGImageRef imageRef = self.CGImage;
    if (!imageRef) {
        return 1;
    }
    BOOL hasAlpha = YCImageRefContainsAlpha(imageRef);
    NSData *imageData;
    if (hasAlpha) {
        imageData = UIImagePNGRepresentation(self);
    } else {
        imageData = UIImageJPEGRepresentation(self, 0.9);
    }
    return MAX(imageData.length, 1);
}

- (NSUInteger)yc_decodeMemoryCost {
    CGImageRef imageRef = self.CGImage;
    size_t height = CGImageGetHeight(imageRef);
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    return MAX(height * bytesPerRow, 1);
}

@end
