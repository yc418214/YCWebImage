//
//  NSData+YCWebImage.h
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/23.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, YCImageType) {
    YCImageTypeUnknown,
    YCImageTypeJPEG,
    YCImageTypePNG,
    YCImageTypeGIF,
    YCImageTypeTIFF,
    YCImageTypeWEBP
};

@interface NSData (YCWebImage)

- (NSString *)yc_md5String;

- (YCImageType)yc_imageType;

- (BOOL)yc_hasPNGPrefix;

@end
