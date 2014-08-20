//
//  HNKNetworkEntity.m
//  Haneke
//
//  Created by Hermes Pique on 7/23/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HNKNetworkEntity.h"

@implementation HNKNetworkEntity {
    NSURL *_URL;
    BOOL _cancelled;
    NSURLSessionDataTask *_dataTask;
}

- (instancetype)initWithURL:(NSURL*)URL
{
    if (self = [super init])
    {
        _URL = URL;
    }
    return self;
}

- (NSString*)cacheKey
{
    return _URL.absoluteString;
}

- (void)fetchImageWithSuccess:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;
{
    _cancelled = NO;
    NSURLSession *session = [NSURLSession sharedSession];
    _dataTask = [session dataTaskWithURL:_URL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (_cancelled) return;
        
        if (error)
        {
            if (error.code == NSURLErrorCancelled) return;
            
            HanekeLog(@"Request %@ failed with error %@", absoluteString, error);
            dispatch_async(dispatch_get_main_queue(), ^
                           {
                               failureBlock(error);
                           });
            return;
        }
        const long long expectedContentLength = response.expectedContentLength;
        if (expectedContentLength > -1)
        {
            const NSUInteger dataLength = data.length;
            if (dataLength < expectedContentLength)
            {
                NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Request %@ received %ld out of %ld bytes", @""), _URL.absoluteString, (long)dataLength, (long)expectedContentLength];
                HanekeLog(@"%@", errorDescription);
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorDescription , NSURLErrorKey : _URL};
                NSError *error = [NSError errorWithDomain:HNKErrorDomain code:HNKNetworkEntityMissingDataError userInfo:userInfo];
                dispatch_async(dispatch_get_main_queue(), ^{
                    failureBlock(error);
                });
                return;
            }
        }
        
        UIImage *image = [UIImage imageWithData:data];
        
        if (!image)
        {
            NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Failed to load image from data at URL %@", @""), _URL];
            HanekeLog(@"%@", errorDescription);
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorDescription , NSURLErrorKey : _URL};
            NSError *error = [NSError errorWithDomain:HNKErrorDomain code:HNKNetworkEntityInvalidDataError userInfo:userInfo];
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            successBlock(image);
        });
        
    }];
    [_dataTask resume];
}

- (void)cancelFetch
{
    [_dataTask cancel];
    _cancelled = YES;
}

@end
