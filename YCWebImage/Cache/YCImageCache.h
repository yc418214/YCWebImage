//
//  YCImageCache.h
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/24.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import <YCCache/YCCache.h>

@class UIImage;

typedef NS_ENUM(NSInteger, YCFetchImageType) {
    YCFetchImageTypeDefault,
    YCFetchImageTypeInMemory,
    YCFetchImageTypeInDisk
};

@interface YCImageCache : YCCache

+ (instancetype)sharedImageCache;

- (void)saveImageInMemory:(UIImage *)image forKey:(NSString *)key;

- (void)saveImageInMemory:(UIImage *)image forKey:(NSString *)key isDecoded:(BOOL)isDecoded;

- (void)saveImageDataInDisk:(NSData *)imageData forKey:(NSString *)key;

- (UIImage *)imageForKey:(NSString *)key;

- (UIImage *)imageForKey:(NSString *)key shouldDecode:(BOOL)shouldDecode;

- (UIImage *)imageForKey:(NSString *)key type:(YCFetchImageType)type;

- (UIImage *)imageForKey:(NSString *)key type:(YCFetchImageType)type shouldDecode:(BOOL)shouldDecode;

@end
