//
//  YCImageDownloader.m
//  YCWebImage
//
//  Created by 陈煜钏 on 2018/1/23.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "YCImageDownloader.h"

#import <UIKit/UIKit.h>
#import <pthread/pthread.h>
//header
#import "YCWebImageMacro.h"
//taskHandler
#import "YCImageDownloadTaskHandler.h"
//operation
#import "YCImageDownloadOperation.h"
//category
#import "NSError+YCWebImage.h"
#import "YCImageDownloader+NetworkActivityIndicator.h"

static CGFloat const kDownloadTimeOut = 60.f;

@interface YCImageDownloadToken ()
@property (strong, nonatomic, readwrite) NSURL *imageURL;
@property (strong, nonatomic) YCImageDownloadTaskHandlerCallbackToken *callbackToken;
+ (instancetype)tokenWithURL:(NSURL *)imageURL callbackToken:(YCImageDownloadTaskHandlerCallbackToken *)callbackToken;
@end

@interface YCImageDownloader () <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (strong, nonatomic) NSURLSession *downloadSession;

@property (strong, nonatomic) NSOperationQueue *downloadOperationQueue;

@property (weak, nonatomic) NSOperation *lastAddedOperation;

@property (strong, nonatomic) NSMutableDictionary<NSURL *, YCImageDownloadTaskHandler *> *taskHandlersDictionary;

@property (copy, nonatomic) YCImageDownloadHeadersDictionary *downloadHeaders;

@end

@implementation YCImageDownloader {
    pthread_mutex_t taskHandlersLock;
}

+ (instancetype)sharedDownloader {
    static YCImageDownloader *downloader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloader = [[YCImageDownloader alloc] init];
    });
    return downloader;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self configDownloader];
    }
    return self;
}

- (void)dealloc {
    [self.downloadSession invalidateAndCancel];
    self.downloadSession = nil;
    
    [self.downloadOperationQueue cancelAllOperations];
}

#pragma mark - public methods

- (YCImageDownloadToken *)downloadImageWithURL:(NSURL *)imageURL
                                 progressBlock:(YCImageDownloadProgressBlock)progressBlock
                               completionBlock:(YCImageDownloadCompletionBlock)completionBlock {
    if (!imageURL) {
        if (completionBlock) {
            NSError *error = [NSError yc_errorWithImageDownloadErrorCode:YCImageDownloadErrorCodeWithoutURL];
            completionBlock(nil, nil, NO, error);
        }
        return nil;
    }
    
    pthread_mutex_lock(&taskHandlersLock);
    YCImageDownloadTaskHandler *taskHandler = self.taskHandlersDictionary[imageURL];
    if (!taskHandler) {
        //create taskHandler
        NSURLRequest *imageURLRequest = [self imageURLRequestWithURL:imageURL];
        taskHandler = [YCImageDownloadTaskHandler handlerWithRequest:imageURLRequest
                                                           inSession:self.downloadSession];
        self.taskHandlersDictionary[imageURL] = taskHandler;
        
        //create operation
        YCImageDownloadOperation *downloadOperation = [[YCImageDownloadOperation alloc] initWithDownloadTask:taskHandler.downloadTask];
        
        WEAKSELF
        //config taskHandler completion block
        YCImageDownloadTaskCompletionBlock downloadCompletionBlock = ^() {
            [downloadOperation cancel];
            
            [weakSelf.taskHandlersDictionary removeObjectForKey:imageURL];
            
            // hide network activity indicator if needed
            [self downloadTaskDidFinish];
        };
        taskHandler.completionBlock = downloadCompletionBlock;
        
        [self.downloadOperationQueue addOperation:downloadOperation];
        if (self.downloadOrder == YCImageDownloaderLIFODownloadOrder) {
            [self.lastAddedOperation addDependency:downloadOperation];
            self.lastAddedOperation = downloadOperation;
        }
        
        // show network activity indicator if needed
        [self addDownloadTask];
    }
    pthread_mutex_unlock(&taskHandlersLock);

    YCImageDownloadTaskHandlerCallbackToken *callbackToken = [taskHandler addProgressBlock:progressBlock completionBlock:completionBlock];
    YCImageDownloadToken *downloadToken = [YCImageDownloadToken tokenWithURL:imageURL callbackToken:callbackToken];
    return downloadToken;
}

- (void)cancelDownloadWithToken:(YCImageDownloadToken *)downloadToken {
    if (!downloadToken) {
        return;
    }
    YCImageDownloadTaskHandler *taskHandler;
    pthread_mutex_lock(&taskHandlersLock);
    taskHandler = self.taskHandlersDictionary[downloadToken.imageURL];
    pthread_mutex_unlock(&taskHandlersLock);
    [taskHandler cancelDownloadWithCallbackToken:downloadToken.callbackToken];
}

- (void)cancelAllDownloads {
    pthread_mutex_lock(&taskHandlersLock);
    for (NSURL *imageURL in self.taskHandlersDictionary) {
        YCImageDownloadTaskHandler *taskHandler = self.taskHandlersDictionary[imageURL];
        [taskHandler cancelDownloadImmediately];
    }
    pthread_mutex_unlock(&taskHandlersLock);
    
    // hide network activity indicator
    [self removeAllDownloadTasks];
}

#pragma mark - private methods

- (void)configDownloader {
    _downloadOperationQueue = [[NSOperationQueue alloc] init];
    _downloadOperationQueue.name = @"com.YCWebImage.ImageDownloadOperationQueue";
    _downloadOperationQueue.maxConcurrentOperationCount = 6;
    
    _taskHandlersDictionary = [NSMutableDictionary dictionary];
    
    _downloadHeaders = @{ @"Accept" : @"image/*;q=0.8" };
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = kDownloadTimeOut;
    _downloadSession = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                     delegate:self
                                                delegateQueue:nil];
    
    pthread_mutex_init(&taskHandlersLock, NULL);
}

- (NSURLRequest *)imageURLRequestWithURL:(NSURL *)imageURL {
    NSMutableURLRequest *imageURLRequest = [NSMutableURLRequest requestWithURL:imageURL
                                                                   cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                               timeoutInterval:kDownloadTimeOut];
    imageURLRequest.HTTPShouldHandleCookies = YES;
    imageURLRequest.HTTPShouldUsePipelining = YES;
    if (self.headersConfigurationBlock) {
        imageURLRequest.allHTTPHeaderFields = self.headersConfigurationBlock(imageURL, self.downloadHeaders);
    } else {
        imageURLRequest.allHTTPHeaderFields = self.downloadHeaders;
    }
    return [imageURLRequest copy];
}

- (YCImageDownloadTaskHandler *)taskHandlerWithTask:(NSURLSessionDataTask *)task {
    __block YCImageDownloadTaskHandler *taskHandler;
    NSDictionary *taskHandlersDictionary;
    pthread_mutex_lock(&taskHandlersLock);
    taskHandlersDictionary = [self.taskHandlersDictionary copy];
    pthread_mutex_unlock(&taskHandlersLock);
    [taskHandlersDictionary enumerateKeysAndObjectsUsingBlock:^(NSURL *imageURL, YCImageDownloadTaskHandler *handler, BOOL *stop) {
        if (handler.downloadTask.taskIdentifier == ((NSURLSessionDownloadTask *)task).taskIdentifier) {
            taskHandler = handler;
            *stop = YES;
        }
    }];
    return taskHandler;
}

#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    [[self taskHandlerWithTask:dataTask] URLSession:session
                                           dataTask:dataTask
                                 didReceiveResponse:response
                                  completionHandler:completionHandler];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    [[self taskHandlerWithTask:dataTask] URLSession:session
                                           dataTask:dataTask
                                     didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler {
    if (completionHandler) {
        completionHandler(nil);
    }
}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    [[self taskHandlerWithTask:(NSURLSessionDataTask *)task] URLSession:session
                                                                   task:task
                                                   didCompleteWithError:error];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    if (completionHandler) {
        completionHandler(request);
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        disposition = NSURLSessionAuthChallengeUseCredential;
    } else {
        BOOL noFailure = (challenge.previousFailureCount == 0);
        BOOL useCredential = (noFailure && self.URLCredential);
        
        disposition = useCredential ?
        NSURLSessionAuthChallengeUseCredential : NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        credential = useCredential ? self.URLCredential : nil;
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

#pragma mark - getter

- (NSUInteger)maxConcurrentDownloadCount {
    return self.downloadOperationQueue.maxConcurrentOperationCount;
}

#pragma mark - setter

- (void)setMaxConcurrentDownloadCount:(NSUInteger)maxConcurrentDownloadCount {
    self.downloadOperationQueue.maxConcurrentOperationCount = maxConcurrentDownloadCount;
}

@end

#pragma mark - YCImageDownloadToken

@implementation YCImageDownloadToken

+ (instancetype)tokenWithURL:(NSURL *)imageURL callbackToken:(YCImageDownloadTaskHandlerCallbackToken *)callbackToken {
    YCImageDownloadToken *downloadToken = [[self alloc] init];
    downloadToken.imageURL = imageURL;
    downloadToken.callbackToken = callbackToken;
    return downloadToken;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"DownloadToken URL : %@", self.imageURL];
}

@end
