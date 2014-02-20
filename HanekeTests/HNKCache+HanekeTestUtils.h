//
//  HNKCache+HanekeTestUtils.h
//  Haneke
//
//  Created by Hermes on 20/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HNKCache.h"

@interface HNKCache (HanekeTestUtils)

+ (id)entityWithKey:(NSString*)key data:(NSData*)data image:(UIImage*)image;

@end
