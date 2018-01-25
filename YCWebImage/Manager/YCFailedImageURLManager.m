//
//  YCFailedImageURLManager.m
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/24.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "YCFailedImageURLManager.h"

static NSUInteger const kImageURLMaxFailedCount = 3;

@interface YCFailedImageURLManager ()

@property (strong, nonatomic) NSMutableSet *failedImageURLSet;

@property (strong, nonatomic) NSMutableDictionary *imageURLFailedCountDictionary;

@end

@implementation YCFailedImageURLManager

+ (instancetype)sharedManager {
    static YCFailedImageURLManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[YCFailedImageURLManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _failedImageURLSet = [NSMutableSet set];
        _imageURLFailedCountDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - public methods

- (void)markImageURLFailedWithURL:(NSURL *)imageURL {
    if (![self shouldDownloadForImageURL:imageURL]) {
        return;
    }
    @synchronized (self.imageURLFailedCountDictionary) {
        NSInteger failedCount = [self.imageURLFailedCountDictionary[imageURL] integerValue];
        failedCount++;
        
        if (failedCount >= kImageURLMaxFailedCount) {
            @synchronized (self.failedImageURLSet) {
                [self.failedImageURLSet addObject:imageURL];
                NSLog(@"Download failed image URL : %@", imageURL);
            }
            [self.imageURLFailedCountDictionary removeObjectForKey:imageURL];
        } else {
            self.imageURLFailedCountDictionary[imageURL] = @(failedCount);
        }
    }
}

- (BOOL)shouldDownloadForImageURL:(NSURL *)imageURL {
    BOOL isImageURLFailed;
    @synchronized (self.failedImageURLSet) {
        isImageURLFailed = [self.failedImageURLSet containsObject:imageURL];
    }
    return !isImageURLFailed;
}

@end
