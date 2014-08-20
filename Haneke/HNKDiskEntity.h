//
//  HNKDiskEntity.h
//  Haneke
//
//  Created by Hermes Pique on 7/23/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HNKCache.h"

enum
{
    HNKDiskEntityInvalidDataError = -500,
};

@interface HNKDiskEntity : NSObject<HNKCacheEntity>

- (instancetype)initWithPath:(NSString*)path;

@end
