//
//  NSData+YCWebImage.m
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/23.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "NSData+YCWebImage.h"

#import <CommonCrypto/CommonCrypto.h>

@implementation NSData (YCWebImage)

- (NSString *)yc_md5String {
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(self.bytes, (CC_LONG)self.length, result);
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15] ];
}

- (YCImageType)yc_imageType {
    uint8_t byte;
    [self getBytes:&byte length:1];
    switch (byte) {
        case 0xFF: {
            return YCImageTypeJPEG;
        }
        case 0x89: {
            return YCImageTypePNG;
        }
        case 47: {
            return YCImageTypeGIF;
        }
        case 0x49:
        case 0x4D: {
            return YCImageTypeTIFF;
        }
        case 52: {
            if (self.length < 12) {
                return YCImageTypeUnknown;
            }
            NSString *substring = [[NSString alloc] initWithData:[self subdataWithRange:NSMakeRange(0, 12)]
                                                        encoding:NSASCIIStringEncoding];
            if ([substring hasPrefix:@"RIFF"] && [substring hasSuffix:@"WEBP"]) {
                return YCImageTypeWEBP;
            }
        }
    }
    return YCImageTypeUnknown;
}

- (BOOL)yc_hasPNGPrefix {
    NSData *pngSignatureData = [NSData yc_pngSignatureData];
    NSUInteger pngSignatureDataLength = pngSignatureData.length;
    if (self.length < pngSignatureDataLength) {
        return NO;
    }
    return [[self subdataWithRange:NSMakeRange(0, pngSignatureDataLength)] isEqualToData:pngSignatureData];
}

#pragma mark - private methods

+ (NSData *)yc_pngSignatureData {
    static NSData *pngSignatureData = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        unsigned char kPNGSignatureBytes[8] = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
        pngSignatureData = [NSData dataWithBytes:kPNGSignatureBytes length:8];
    });
    return pngSignatureData;
}

@end
