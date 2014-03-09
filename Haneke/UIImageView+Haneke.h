//
//  UIImageView+Haneke.h
//  Haneke
//
//  Created by Hermes on 12/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HNKCache.h"

@interface UIImageView (Haneke)

- (void)hnk_setImageFromFile:(NSString*)path;

- (void)hnk_setImageFromFile:(NSString*)path placeholderImage:(UIImage*)placeholderImage;

- (void)hnk_setImageFromFile:(NSString*)path failure:(void (^)(NSError *error))failureBlock;

- (void)hnk_setImageFromFile:(NSString*)path placeholderImage:(UIImage*)placeholderImage failure:(void (^)(NSError *error))failureBlock;

- (void)hnk_setImageFromURL:(NSURL*)url;

- (void)hnk_setImageFromURL:(NSURL*)url placeholderImage:(UIImage*)placeholderImage;

- (void)hnk_setImageFromURL:(NSURL*)url failure:(void (^)(NSError *error))failureBlock;

- (void)hnk_setImageFromURL:(NSURL*)url placeholderImage:(UIImage*)placeholderImage failure:(void (^)(NSError *error))failureBlock;

- (void)hnk_setImage:(UIImage*)image withKey:(NSString*)key;

- (void)hnk_setImageFromEntity:(id<HNKCacheEntity>)entity;

@property (nonatomic, strong) HNKCacheFormat *hnk_cacheFormat;

@end

enum
{
    HNKErrorImageFromURLMissingData = -400,
};
