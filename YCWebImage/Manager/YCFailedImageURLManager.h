//
//  YCFailedImageURLManager.h
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/24.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YCFailedImageURLManager : NSObject

+ (instancetype)sharedManager;

- (void)markImageURLFailedWithURL:(NSURL *)imageURL;

- (BOOL)shouldDownloadForImageURL:(NSURL *)imageURL;

@end
