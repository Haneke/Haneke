//
//  HNKCache+HanekeTestUtils.m
//  Haneke
//
//  Created by Hermes on 20/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HNKCache+HanekeTestUtils.h"
#import <OCMock/OCMock.h>

@implementation HNKCache (HanekeTestUtils)

+ (id)entityWithKey:(NSString*)key data:(NSData*)data image:(UIImage*)image
{
    id entity = [OCMockObject mockForProtocol:@protocol(HNKCacheEntity)];
    [[[entity stub] andReturn:key] cacheKey];
    [[[entity stub] andReturn:data] cacheOriginalData];
    [[[entity stub] andReturn:image] cacheOriginalImage];
    return entity;
}

@end
