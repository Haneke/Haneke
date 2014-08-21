//
//  HNKNetworkEntity.m
//  Haneke
//
//  Created by Hermes Pique on 7/23/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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
    _dataTask = [self.URLSession dataTaskWithURL:_URL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (_cancelled) return;
        
        if (error)
        {
            if (error.code == NSURLErrorCancelled) return;
            
            HanekeLog(@"Request %@ failed with error %@", _URL.absoluteString, error);
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
                NSError *error = [NSError errorWithDomain:HNKErrorDomain code:HNKErrorNetworkEntityMissingData userInfo:userInfo];
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
            NSError *error = [NSError errorWithDomain:HNKErrorDomain code:HNKErrorNetworkEntityInvalidData userInfo:userInfo];
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

@implementation HNKNetworkEntity(Subclassing)

- (NSURLSession*)URLSession
{
    return [NSURLSession sharedSession];
}

@end
