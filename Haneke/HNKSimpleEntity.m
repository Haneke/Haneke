//
//  HNKSimpleEntity.m
//  Haneke
//
//  Created by Hermes Pique on 8/19/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HNKSimpleEntity.h"

@implementation HNKSimpleEntity {
    NSString *_key;
    UIImage *_image;
}

- (instancetype)initWithKey:(NSString*)key image:(UIImage*)image
{
    if (self = [super init])
    {
        _key = [key copy];
        _image = image;
    }
    return self;
}

- (NSString*)cacheKey
{
    return _key;
}

- (void)fetchImageWithSuccess:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;
{
    successBlock(_image);
}

@end
