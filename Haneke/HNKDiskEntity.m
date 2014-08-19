//
//  HNKDiskEntity.m
//  Haneke
//
//  Created by Hermes Pique on 7/23/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HNKDiskEntity.h"

@implementation HNKDiskEntity {
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

- (NSString*)cacheKey
{
    return _path;
}

- (void)fetchImageWithSuccess:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;
{
    _cancelled = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (_cancelled) return;
        
        NSError *error = nil;
        NSData *data = [NSData dataWithContentsOfFile:_path options:kNilOptions error:&error];
        if (!data)
        {
            HanekeLog(@"Request %@ failed with error %@", path, error);
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error);
            });
            return;
        }
        
        if (_cancelled) return;
        
        UIImage *image = [UIImage imageWithData:data];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_cancelled) return;
            
            successBlock(image);
        });
    });
}

- (void)cancelFetch
{
    _cancelled = YES;
}

@end
