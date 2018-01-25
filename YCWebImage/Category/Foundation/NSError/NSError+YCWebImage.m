//
//  NSError+YCWebImage.m
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/23.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "NSError+YCWebImage.h"

static NSString * const YCImageManagerErrorDomain = @"YCWebImageErrorDomain";

@implementation NSError (YCWebImage)

+ (NSError *)yc_errorWithImageDownloadErrorCode:(YCImageDownloadErrorCode)errorCode {
    return [NSError errorWithDomain:YCImageManagerErrorDomain
                               code:errorCode
                           userInfo:[self yc_imageDownloadUserInfoWithErrorCode:errorCode]];
}

#pragma mark - private methods

+ (NSDictionary *)yc_imageDownloadUserInfoWithErrorCode:(YCImageDownloadErrorCode)errorCode {
    NSString *errorMessage;
    switch (errorCode) {
        case YCImageDownloadErrorCodeWithoutURL: {
            errorMessage = @"Without image URL";
            break;
        }
        case YCImageDownloadErrorCodeEmptyImageData: {
            errorMessage = @"Downloaded image data is nil";
            break;
        }
        case YCImageDownloadErrorCodeWithoutPixel: {
            errorMessage = @"Downloaded image has zero pixel";
            break;
        }
        case YCImageDownloadErrorCodeDownloadCancelled: {
            errorMessage = @"Download task is cancelled";
            break;
        }
        default: {
            errorMessage = @"Unknown error";
            break;
        }
    }
    return @{ NSLocalizedDescriptionKey : errorMessage };
}

@end
