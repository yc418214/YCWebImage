//
//  NSString+YCWebImage.m
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/24.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "NSString+YCWebImage.h"

//category
#import "NSData+YCWebImage.h"

@implementation NSString (YCWebImage)

- (instancetype)yc_md5String {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] yc_md5String];
}

@end
