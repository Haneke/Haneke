//
//  HNKItem.h
//  Haneke
//
//  Created by Hermes on 11/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HNKCache.h"

@interface HNKItem : NSObject<HNKCacheEntity>

@property (nonatomic, assign) NSUInteger index;

+ (HNKItem*)itemWithIndex:(NSUInteger)index;

@end
