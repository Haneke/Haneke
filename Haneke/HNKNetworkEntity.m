//
//  HNKNetworkEntity.m
//  Haneke
//
//  Created by Hermes Pique on 7/23/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HNKNetworkEntity.h"
#import "UIImage+Haneke.h"

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

- (void)retrieveImageWithCompletionBlock:(void(^)(UIImage *image, NSError *error))completionBlock
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
                               completionBlock(nil, error);
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
                NSError *error = [NSError errorWithDomain:HNKErrorDomain code:HNKNetworkEntityLMissingData userInfo:userInfo];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, error);
                });
                return;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *image = [UIImage hnk_decompressedImageWithData:data];
            completionBlock(image, nil);
        });
        
    }];
    [_dataTask resume];
}

- (void)cancelRetrieve
{
    [_dataTask cancel];
    _cancelled = YES;
}


@end
