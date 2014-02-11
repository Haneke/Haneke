//
//  HNKCache.h
//  Haneke
//
//  Created by Hermes on 10/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HNKCacheEntity;
@class HNKCacheFormat;

@interface HNKCache : NSObject

#pragma mark Initializing the cache
///---------------------------------------------
/// @name Initializing the cache
///---------------------------------------------

- (id)initWithName:(NSString*)name;

+ (HNKCache*)sharedCache;

- (void)registerFormat:(HNKCacheFormat*)format;

#pragma mark Getting images
///---------------------------------------------
/// @name Getting images
///---------------------------------------------

- (UIImage*)imageForEntity:(id<HNKCacheEntity>)entity formatName:(NSString *)formatName;

- (BOOL)retrieveImageForEntity:(id<HNKCacheEntity>)entity formatName:(NSString *)formatName completionBlock:(void(^)(id<HNKCacheEntity> entity, NSString *formatName, UIImage *image))completionBlock;

#pragma mark Removing images
///---------------------------------------------
/// @name Removing images
///---------------------------------------------

- (void)clearFormatNamed:(NSString*)formatName;

- (void)removeImagesOfEntity:(id<HNKCacheEntity>)entity;

@end

@protocol HNKCacheEntity <NSObject>

@property (nonatomic, readonly) NSString *cacheId;
/**
 Return the original image associated with the entity, or nil to use cacheOriginalData instead.
 */
@property (nonatomic, readonly) UIImage *cacheOriginalImage;
/**
 Return the original data associated with the entity, or nil to use cacheOriginalImage instead.
 */
@property (nonatomic, readonly) NSData *cacheOriginalData;


@end

typedef NS_ENUM(NSInteger, HNKScaleMode)
{
    HNKScaleModeFill = UIViewContentModeScaleToFill,
    HNKScaleModeAspectFit = UIViewContentModeScaleAspectFit,
    HNKScaleModeAspectFill = UIViewContentModeScaleAspectFill
};

@interface HNKCacheFormat : NSObject

@property (nonatomic, assign) BOOL allowUpscaling;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) HNKScaleMode scaleMode;
@property (nonatomic, assign) unsigned long long diskCapacity;
@property (nonatomic, readonly) unsigned long long diskSize;

- (id)initWithName:(NSString*)name;

- (UIImage*)resizedImageFromImage:(UIImage*)image;

@end
