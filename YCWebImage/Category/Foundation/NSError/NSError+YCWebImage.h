//
//  NSError+YCWebImage.h
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/23.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, YCImageDownloadErrorCode) {
    YCImageDownloadErrorCodeWithoutURL,
    YCImageDownloadErrorCodeEmptyImageData,
    YCImageDownloadErrorCodeWithoutPixel,
    YCImageDownloadErrorCodeDownloadCancelled,
    YCImageDownloadErrorCodeFailedURL
};

@interface NSError (YCWebImage)

+ (NSError *)yc_errorWithImageDownloadErrorCode:(YCImageDownloadErrorCode)errorCode;

@end
