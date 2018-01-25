//
//  YCWebImageBlock.h
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/23.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#ifndef YCWebImageBlock_h
#define YCWebImageBlock_h

@class UIImage;

//download progress
typedef void(^YCImageDownloadProgressBlock)(NSUInteger receivedLength, NSUInteger expectedLength, NSURL *imageURL);
//download completion
typedef void(^YCImageDownloadCompletionBlock)(UIImage *image, NSData *imageData, BOOL isCancelled, NSError *error);

#endif /* YCWebImageBlock_h */
