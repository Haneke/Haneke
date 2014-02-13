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

/**
 Initialize a cache with the given name.
 @param name Name of the cache. Used to as the name of the subdirectory for the disk cache.
*/
- (id)initWithName:(NSString*)name;

/**
 Returns the shared cache. For simple apps that don't require multiple caches.
 */
+ (HNKCache*)sharedCache;

/**
 Registers a format in the cache. Haneke will automatically update the diskSize of the format as images are added. If a format with the same name already exists in the cache, it will be cleared first.
 @param The format to be registered in the cache.
 @discussion If the format preload policy allows it, Haneke will add some or all images cached on disk to the memory cache while there is no user activity.
 @discussion A format can only be registered in one cache.
 */
- (void)registerFormat:(HNKCacheFormat*)format;

/**
 Dictionary of formats registered with the cache.
 */
@property (nonatomic, readonly) NSDictionary *formats;

#pragma mark Getting images
///---------------------------------------------
/// @name Getting images
///---------------------------------------------

/**
 Synchronously retrieves an image from the cache, or creates it it doesn't exist. 
 @param entity Entity that represents the original image. If the image doesn't exist in the cache, the entity will be asked to provide the original data or image to create it.
 @param formatName Name of the format in which the image is desired. The format must have been previously registered with the cache. If the image doesn't exist in the cache, it will be created based on the format. If by creating the image the format disk capacity is surpassed, least recently used images of the format will be removed until it isn't.
 @discussion Disk operations such as saving the image are performed asynchronously, even if the image is returned synchronously.
 */
- (UIImage*)imageForEntity:(id<HNKCacheEntity>)entity formatName:(NSString *)formatName;

/**
 Retrieves an image from the cache, or creates it it doesn't exist. If the image exists in the memory cache, the completion block will be executed synchronously. If the image exists in the disk cache or has to be created, the completion block will be executed asynchronously.
 @param entity Entity that represents the original image. If the image doesn't exist in the cache, the entity will be asked to provide the original data or image to create it. Any calls to the entity will be done in the main queue.
 @param formatName Name of the format in which the image is desired. The format must have been previously registered with the cache. If the image doesn't exist in the cache, it will be created based on the format. If by creating the image the format disk capacity is surpassed, least recently used images of the format will be removed until it isn't.
 @param completionBlock The block to be called with the requested image. Always called from the main queue. Will be called synchronously if the image exists in the memory cache, or asynchronously if the image exists in the disk cache or had to be created.
 @return YES if image exists in the memory cache (and thus, the completion block was called synchronously), NO otherwise.
 */
- (BOOL)retrieveImageForEntity:(id<HNKCacheEntity>)entity formatName:(NSString *)formatName completionBlock:(void(^)(id<HNKCacheEntity> entity, NSString *formatName, UIImage *image))completionBlock;

/**
 Retrieves an image from the cache. If the image exists in the memory cache, the completion block will be executed synchronously. If the image exists in the disk cache, the completion block will be executed asynchronously.
 @param key Image cache key.
 @param formatName Name of the format in which the image is desired. The format must have been previously registered with the cache.
 @param completionBlock The block to be called with the requested image. Always called from the main queue. Will be called synchronously if the image exists in the memory cache, or asynchronously if the image exists in the disk cache.
 @return YES if image exists in the memory cache (and thus, the completion block was called synchronously), NO otherwise.
 */
- (BOOL)retrieveImageForKey:(NSString*)key formatName:(NSString *)formatName completionBlock:(void(^)(NSString *key, NSString *formatName, UIImage *image))completionBlock;

#pragma mark Setting images
///---------------------------------------------
/// @name Setting images
///---------------------------------------------

/**
 Sets the image of the given key for the given format. The image is added to the memory cache and the disk cache if the format allows it.
 @param image Image to add to the cache. Can be nil, in which case the current image associated to the given key and format will be removed.
 @param key Image cache key.
 @param formatName Name of the format of the given image.
 @discussion You can use this method to pre-populate the cache, invalidate a specific image or to add resized images obtained elsewhere (e.g., a web service that generates thumbnails). In other cases, it's best to let the cache create the resized images.
 @warning The image size should match the format. This method won't validate this.
 */
- (void)setImage:(UIImage*)image forKey:(NSString*)key formatName:(NSString*)formatName;

#pragma mark Removing images
///---------------------------------------------
/// @name Removing images
///---------------------------------------------

/** Removes all images of the given format.
 @param formatName Name of the format whose images will be removed.
 */
- (void)clearFormatNamed:(NSString*)formatName;

/** Removes all images of the given entity.
 @param entity Entity whose images will be removed.
 */
- (void)removeImagesOfEntity:(id<HNKCacheEntity>)entity;

@end

/** Represents an object that is associated with an image. Used by the cache to assign identifiers to images and obtain the original data or image needed to create resized images. **/
@protocol HNKCacheEntity <NSObject>

/** 
 Return a key for the original image associated with the entity.
 @discussion If two different entities have the same image, they should return the same key for better performance.
 */
@property (nonatomic, readonly) NSString *cacheKey;
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

typedef NS_ENUM(NSInteger, HNKPreloadPolicy)
{
    HNKPreloadPolicyNone,
    HNKPreloadPolicyLastSession,
    HNKPreloadPolicyAll
};

/**
 Image cache format. Defines the transformation applied to images as well as cache policies such as disk capacity.
 */
@interface HNKCacheFormat : NSObject

/**
 Allow upscalling. Images smaller than the format size will be upscaled if set to YES. NO by default.
 */
@property (nonatomic, assign) BOOL allowUpscaling;

/**
 The quality of the resulting JPEG image, expressed as a value from 0.0 to 1.0. The value 0.0 represents the maximum compression (or lowest quality) while the value 1.0 represents the least compression (or best quality). 1.0 by default.
 */
@property (nonatomic, assign) CGFloat compressionQuality;

/**
 Format name. Used by the cache as the directory name for the disk cache of the format.
 */
@property (nonatomic, readonly) NSString *name;

/**
 Format image size. Images will be scaled to fit or fill this size based on scaleMode.
 */
@property (nonatomic, assign) CGSize size;

/**
 Format scale mode. Determines if images will fit or fill the format size, and if the aspect ratio will be mantained or not. HNKScaleModeFill by default.
 */
@property (nonatomic, assign) HNKScaleMode scaleMode;

/**
 The disk cache capacity for the format. If 0 Haneke will only use memory cache. 0 by default.
 */
@property (nonatomic, assign) unsigned long long diskCapacity;

/**
 Current size in bytes of the disk cache used by the format.
 */
@property (nonatomic, readonly) unsigned long long diskSize;

/**
 Preload policy. If set, Haneke will add some or all images cached on disk to the memory cache. HNKPreloadPolicyNone by default.
 */
@property (nonatomic, assign) HNKPreloadPolicy preloadPolicy;

/** Initializes a format with the given name.
 @param name Name of the format.
 */
- (id)initWithName:(NSString*)name;

/**
 Resized the given image based on the format. Used by the cache to create its images.
 @param image The original image.
 @return A resized image based on the format.
 */
- (UIImage*)resizedImageFromImage:(UIImage*)image;

@end
