//
//  HNKNetworkFetcher.m
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

#import "HNKNetworkFetcher.h"

@implementation HNKNetworkFetcher {
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

- (NSString*)key
{
    return _URL.absoluteString;
}

- (void)fetchImageWithSuccess:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;
{
    _cancelled = NO;
    __weak __typeof__(self) weakSelf = self;
    _dataTask = [self.URLSession dataTaskWithURL:_URL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        __strong __typeof__(weakSelf) strongSelf = weakSelf;

        if (!strongSelf) return;

        if (strongSelf->_cancelled) return;
        
        NSURL *URL = strongSelf->_URL;
        
        if (error)
        {
            if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) return;
            
            HanekeLog(@"Request %@ failed with error %@", URL.absoluteString, error);
            if (!failureBlock) return;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
            return;
        }
        
        if (![response isKindOfClass:NSHTTPURLResponse.class])
        {
            HanekeLog(@"Request %@ received unknown response %@", URL.absoluteString, response);
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        if (httpResponse.statusCode != 200)
        {
            NSString *errorDescription = [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode];
            [strongSelf failWithLocalizedDescription:errorDescription code:HNKErrorNetworkFetcherInvalidStatusCode block:failureBlock];
            return;
        }
        
        const long long expectedContentLength = response.expectedContentLength;
        if (expectedContentLength > -1)
        {
            const NSUInteger dataLength = data.length;
            if (dataLength < expectedContentLength)
            {
                NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Request %@ received %ld out of %ld bytes", @""), URL.absoluteString, (long)dataLength, (long)expectedContentLength];
                [strongSelf failWithLocalizedDescription:errorDescription code:HNKErrorNetworkFetcherMissingData block:failureBlock];
                return;
            }
        }
        
        UIImage *image = [UIImage imageWithData:data];
        
        if (!image)
        {
            NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Failed to load image from data at URL %@", @""), URL];
            [strongSelf failWithLocalizedDescription:errorDescription code:HNKErrorNetworkFetcherInvalidData block:failureBlock];
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

- (void)dealloc
{
    [self cancelFetch];
}

#pragma mark Private

- (void)failWithLocalizedDescription:(NSString*)localizedDescription code:(NSInteger)code block:(void (^)(NSError *error))failureBlock;
{
    HanekeLog(@"%@", localizedDescription);
    if (!failureBlock) return;

    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : localizedDescription , NSURLErrorKey : _URL};
    NSError *error = [NSError errorWithDomain:HNKErrorDomain code:code userInfo:userInfo];
    dispatch_async(dispatch_get_main_queue(), ^{
        failureBlock(error);
    });
}

@end

@implementation HNKNetworkFetcher(Subclassing)

- (NSURLSession*)URLSession
{
    return [NSURLSession sharedSession];
}

@end
