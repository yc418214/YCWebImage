//
//  YCImageDownloader+NetworkActivityIndicator.h
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/25.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "YCImageDownloader.h"

@interface YCImageDownloader (NetworkActivityIndicator)

- (void)addDownloadTask;

- (void)downloadTaskDidFinish;

- (void)removeAllDownloadTasks;

@end
