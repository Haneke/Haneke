//
//  HNKDiskFetcher.m
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

#import "HNKDiskFetcher.h"

@implementation HNKDiskFetcher {
    NSString *_path;
    BOOL _cancelled;
}

- (instancetype)initWithPath:(NSString*)path
{
    if (self = [super init])
    {
        _path = path;
    }
    return self;
}

- (NSString*)key
{
    return _path;
}

- (void)fetchImageWithSuccess:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;
{
    _cancelled = NO;
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __strong __typeof__(weakSelf) strongSelf = weakSelf;

        if (!strongSelf) return;

        if (strongSelf->_cancelled) return;
        
        NSString *path = strongSelf->_path;
        
        NSError *error = nil;
        NSData *data = [NSData dataWithContentsOfFile:path options:kNilOptions error:&error];
        if (!data)
        {
            HanekeLog(@"Request %@ failed with error %@", path, error);
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
            return;
        }
        
        if (strongSelf->_cancelled) return;
        
        UIImage *image = [UIImage imageWithData:data];
        
        if (!image)
        {
            NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Failed to load image from data at path %@", @""), path];
            HanekeLog(@"%@", errorDescription);
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorDescription , NSFilePathErrorKey : path};
            NSError *error = [NSError errorWithDomain:HNKErrorDomain code:HNKErrorDiskFetcherInvalidData userInfo:userInfo];
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (strongSelf->_cancelled) return;
            
            successBlock(image);
        });
    });
}

- (void)cancelFetch
{
    _cancelled = YES;
}

- (void)dealloc
{
    [self cancelFetch];
}

@end
