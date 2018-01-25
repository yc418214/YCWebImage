//
//  YCImageIODecoder.m
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/23.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "YCImageIODecoder.h"

#import <ImageIO/ImageIO.h>

static CGColorSpaceRef YCColorSpaceGetDeviceRGB() {
    static CGColorSpaceRef colorSpaceRef = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    });
    return colorSpaceRef;
}

static UIImage *YCDecodedImage (CGImageRef originalImageRef, CGFloat scale, UIImageOrientation imageOrientation);

@interface YCImageIODecoder ()

@property (assign, nonatomic) CGImageSourceRef imageSourceRef;

@property (strong, nonatomic) UIImage *originalImage;

@property (assign, nonatomic) CGFloat scale;

@property (assign, nonatomic, readwrite) UIImageOrientation imageOrientation;

@property (strong, nonatomic, readwrite) UIImage *decodedImage;

@end

@implementation YCImageIODecoder

+ (instancetype)decoderWithImageData:(NSData *)imageData scale:(CGFloat)scale {
    return [[self alloc] initWithImageData:imageData scale:scale];
}

+ (instancetype)decoderWithImage:(UIImage *)image {
    return [[self alloc] initWithImage:image];
}

- (instancetype)initWithImageData:(NSData *)imageData scale:(CGFloat)scale {
    self = [super init];
    if (self) {
        _imageSourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
        _scale = scale;
        _imageOrientation = [YCImageIODecoder imageOrientationWithImageSource:_imageSourceRef];
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image {
    self = [super init];
    if (self) {
        _originalImage = image;
        _scale = image.scale;
        _imageOrientation = image.imageOrientation;
    }
    return self;
}

- (void)dealloc {
    if (_imageSourceRef) {
        CFRelease(_imageSourceRef);
    }
}

#pragma mark - public methods

+ (UIImageOrientation)imageOrientationWithImageSource:(CGImageSourceRef)imageSource {
    UIImageOrientation imageOrientation = UIImageOrientationUp;
    if (!imageSource) {
        return imageOrientation;
    }
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
    if (!properties) {
        return UIImageOrientationUp;
    }
    int exifOrientation;
    CFTypeRef value = CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
    if (!value) {
        CFRelease(properties);
        return UIImageOrientationUp;
    }
    CFNumberGetValue(value, kCFNumberIntType, &exifOrientation);
    imageOrientation = [self imageOrientationFromExifOriention:exifOrientation];
    CFRelease(properties);
    return imageOrientation;
}

#pragma mark - private methods

- (UIImage *)innerDecodedImage {
    CGImageRef imageRef = NULL;
    if (_originalImage) {
        imageRef = (CGImageRef)CFRetain(_originalImage.CGImage);
    } else if (_imageSourceRef) {
        NSDictionary *options = @{ (id)kCGImageSourceShouldCache : @(YES) };
        imageRef = CGImageSourceCreateImageAtIndex(_imageSourceRef, 0, (CFDictionaryRef)options);
    }
    if (!imageRef) {
        return nil;
    }
    UIImage *decodedImage = YCDecodedImage(imageRef, _scale, _imageOrientation);
    CFRelease(imageRef);
    return decodedImage;
}

// reference see here: http://sylvana.net/jpegcrop/exif_orientation.html
+ (UIImageOrientation)imageOrientationFromExifOriention:(NSInteger)exifOrientation {
    UIImageOrientation orientation = UIImageOrientationUp;
    switch (exifOrientation) {
        case kCGImagePropertyOrientationUp:
            orientation = UIImageOrientationUp;
            break;
        case kCGImagePropertyOrientationDown:
            orientation = UIImageOrientationDown;
            break;
        case kCGImagePropertyOrientationLeft:
            orientation = UIImageOrientationLeft;
            break;
        case kCGImagePropertyOrientationRight:
            orientation = UIImageOrientationRight;
            break;
        case kCGImagePropertyOrientationUpMirrored:
            orientation = UIImageOrientationUpMirrored;
            break;
        case kCGImagePropertyOrientationDownMirrored:
            orientation = UIImageOrientationDownMirrored;
            break;
        case kCGImagePropertyOrientationLeftMirrored:
            orientation = UIImageOrientationLeftMirrored;
            break;
        case kCGImagePropertyOrientationRightMirrored:
            orientation = UIImageOrientationRightMirrored;
            break;
        default:
            break;
    }
    return orientation;
}

#pragma mark - getter

- (UIImage *)decodedImage {
    if (_decodedImage) {
        return _decodedImage;
    }
    _decodedImage = [self innerDecodedImage];
    return _decodedImage;
}

@end

#pragma mark - YCDecodedImage

UIImage *YCDecodedImage (CGImageRef originalImageRef, CGFloat scale, UIImageOrientation imageOrientation) {
    if (!originalImageRef) {
        return nil;
    }
    CGImageRef imageRef = (CGImageRef)CFRetain(originalImageRef);
    size_t imageWidth = CGImageGetWidth(imageRef);
    size_t imageHeight = CGImageGetHeight(imageRef);
    if (imageWidth == 0 || imageHeight == 0) {
        CFRelease(imageRef);
        return nil;
    }
    __block UIImage *decodedImage;
    @autoreleasepool {
        BOOL hasAlpha = YCImageRefContainsAlpha(imageRef);
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
        bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
        
        CGContextRef contextRef = CGBitmapContextCreate(NULL, imageWidth, imageHeight, 8, 0, YCColorSpaceGetDeviceRGB(), bitmapInfo);
        if (!contextRef) {
            CFRelease(imageRef);
            return nil;
        }
        CGContextDrawImage(contextRef, CGRectMake(0, 0, imageWidth, imageHeight), imageRef);
        CGImageRef decodedImageRef = CGBitmapContextCreateImage(contextRef);
        
        CFRelease(contextRef);
        CFRelease(imageRef);
        
        decodedImage = [UIImage imageWithCGImage:decodedImageRef scale:scale orientation:imageOrientation];
        
        CFRelease(decodedImageRef);
    }
    return decodedImage;
}

BOOL YCImageRefContainsAlpha (CGImageRef imageRef) {
    if (!imageRef) {
        return NO;
    }
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    return hasAlpha;
}
