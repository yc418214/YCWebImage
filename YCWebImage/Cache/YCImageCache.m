//
//  YCImageCache.m
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/24.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "YCImageCache.h"

//category
#import "UIImage+YCWebImage.h"

static NSString * const kImageCacheName = @"YCImageCache";

@interface YCImageCache ()

@end

@implementation YCImageCache

+ (instancetype)sharedImageCache {
    static YCImageCache *imageCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageCache = [super cacheWithName:kImageCacheName
                    diskCacheStorePolicy:YCDiskCacheStorePolicyFile];
    });
    return imageCache;
}

#pragma mark - public methods

- (void)saveImageInMemory:(UIImage *)image forKey:(NSString *)key {
    [self saveImageInMemory:image forKey:key isDecoded:NO];
}

- (void)saveImageInMemory:(UIImage *)image forKey:(NSString *)key isDecoded:(BOOL)isDecoded {
    NSUInteger memoryCost = isDecoded ? [image yc_decodeMemoryCost] : [image yc_memoryCost];
    [self.memoryCache storeObject:image forKey:key memoryCost:memoryCost];
}

- (void)saveImageDataInDisk:(NSData *)imageData forKey:(NSString *)key {
    [self.diskCache storeData:imageData forKey:key];
}

- (UIImage *)imageForKey:(NSString *)key {
    return [self imageForKey:key type:YCFetchImageTypeDefault shouldDecode:NO];
}

- (UIImage *)imageForKey:(NSString *)key shouldDecode:(BOOL)shouldDecode {
    return [self imageForKey:key type:YCFetchImageTypeDefault shouldDecode:shouldDecode];
}

- (UIImage *)imageForKey:(NSString *)key type:(YCFetchImageType)type {
    return [self imageForKey:key type:type shouldDecode:NO];
}

- (UIImage *)imageForKey:(NSString *)key type:(YCFetchImageType)type shouldDecode:(BOOL)shouldDecode {
    if (type == YCFetchImageTypeInDisk) {
        return [self imageFromDiskForKey:key shouldDecode:shouldDecode];
    }
    UIImage *image = [self.memoryCache objectForKey:key];
    if (type == YCFetchImageTypeInMemory) {
        return image;
    }
    if (image) {
        return image;
    }
    image = [self imageFromDiskForKey:key shouldDecode:shouldDecode];
    
    [self saveImageInMemory:image forKey:key];
    return image;
}

#pragma mark - private methods

- (UIImage *)imageFromDiskForKey:(NSString *)key shouldDecode:(BOOL)shouldDecode {
    NSData *imageData = [self.diskCache dataForKey:key];
    UIImage *image = shouldDecode ?
    [UIImage yc_decodedImageWithData:imageData] : [UIImage imageWithData:imageData];
    return image;
}

@end
