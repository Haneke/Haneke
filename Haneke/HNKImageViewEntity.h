//
//  HNKImageViewEntity.h
//  Pods
//
//  Created by Aleix Ventayol on 26/05/14.
//
//

#import <Foundation/Foundation.h>
#import "HNKCache.h"

@protocol HNKCacheEntity;

@interface HNKImageViewEntity : NSObject<HNKCacheEntity>

+ (HNKImageViewEntity*)entityWithImage:(UIImage*)image key:(NSString*)key;

+ (HNKImageViewEntity*)entityWithData:(NSData*)data key:(NSString*)key;

@end
