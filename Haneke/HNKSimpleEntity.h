//
//  HNKSimpleEntity.h
//  Haneke
//
//  Created by Hermes Pique on 8/19/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HNKCache.h"

@interface HNKSimpleEntity : NSObject<HNKCacheEntity>

- (instancetype)initWithKey:(NSString*)key image:(UIImage*)image;

@end
