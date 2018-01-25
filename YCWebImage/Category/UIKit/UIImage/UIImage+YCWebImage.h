//
//  UIImage+YCWebImage.h
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/23.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (YCWebImage)

+ (instancetype)yc_decodedImageWithData:(NSData *)data;

- (instancetype)yc_decodedImage;

- (NSUInteger)yc_memoryCost;

- (NSUInteger)yc_decodeMemoryCost;

@end
