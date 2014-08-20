//
//  HNKNetworkEntity.h
//  Haneke
//
//  Created by Hermes Pique on 7/23/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HNKCache.h"

enum
{
    HNKNetworkEntityInvalidDataError = -400,
    HNKNetworkEntityMissingDataError = -401,
};

@interface HNKNetworkEntity : NSObject<HNKCacheEntity>

- (instancetype)initWithURL:(NSURL*)URL;

@end
