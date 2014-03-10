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

/** Loads, resizes, displays and caches an appropiately sized image from the given path.
 @param path Path from which the image will be loaded if it's not available in the cache.
 @see hnk_setImageFromFile:placeholderImage:failure:
 **/
- (void)hnk_setImageFromFile:(NSString*)path;

/** Loads, resizes, displays and caches an appropiately sized image from the given path.
 @param path Path from which the image will be loaded if it's not available in the cache.
 @param placeholderImage Image to be used as a placeholder until the requested image is ready. The placeholder image will only be used if the requested image is not available in the memory cache. If nil, the image view will not change its image until the requested image is ready.
 @see hnk_setImageFromFile:placeholderImage:failure:
 **/
- (void)hnk_setImageFromFile:(NSString*)path placeholderImage:(UIImage*)placeholderImage;

/** Loads, resizes, displays and caches an appropiately sized image from the given path.
 @param path Path from which the image will be loaded if it's not available in the cache.
 @param failureBlock Block to be called if an error occurs. The most likely cause of error is that the given path does not contain an image.
 @see hnk_setImageFromFile:placeholderImage:failure:
 **/
- (void)hnk_setImageFromFile:(NSString*)path failure:(void (^)(NSError *error))failureBlock;

/** Loads, resizes, displays and caches an appropiately sized image from the given path.
 @param path Path from which the image will be loaded if it's not available in the cache.
 @param placeholderImage Image to be used as a placeholder until the requested image is ready. The placeholder image will only be used if the requested image is not available in the memory cache. If nil, the image view will not change its image until the requested image is ready.
 @param failureBlock Block to be called if an error occurs. The most likely cause of error is that the given path does not contain an image.
 @discussion Retrieves an appropiately sized image (based on the bounds and contentMode of the UIImageView) from the memory or disk cache. Disk access is performed in background. If not cached, loads the original image from disk, produces an appropiately sized image and caches the result, everything in background.
 @discussion If the requested image is available in the memory cache it will be set synchronously and without animation. In any other case, the image will be set with a short fade animation once its ready.
 @discussion If needed, the least recently used images in the cache will be evicted in background.
 **/
- (void)hnk_setImageFromFile:(NSString*)path placeholderImage:(UIImage*)placeholderImage failure:(void (^)(NSError *error))failureBlock;

/** Loads, resizes, displays and caches an appropiately sized image from the given url.
 @param url Url from which the image will be loaded if it's not available in the cache.
 @see hnk_setImageFromURL:placeholderImage:failure:
 **/
- (void)hnk_setImageFromURL:(NSURL*)url;

/** Loads, resizes, displays and caches an appropiately sized image from the given url.
 @param url Url from which the image will be loaded if it's not available in the cache.
 @param placeholderImage Image to be used as a placeholder until the requested image is ready. The placeholder image will only be used if the requested image is not available in the memory cache. If nil, the image view will not change its image until the requested image is ready.
 @see hnk_setImageFromURL:placeholderImage:failure:
 **/
- (void)hnk_setImageFromURL:(NSURL*)url placeholderImage:(UIImage*)placeholderImage;

/** Loads, resizes, displays and caches an appropiately sized image from the given url.
 @param url Url from which the image will be loaded if it's not available in the cache.
 @param failureBlock Block to be called if an error occurs. The most likely cause of error is that the given path does not contain an image.
 @see hnk_setImageFromURL:placeholderImage:failure:
 **/
- (void)hnk_setImageFromURL:(NSURL*)url failure:(void (^)(NSError *error))failureBlock;

/** Loads, resizes, displays and caches an appropiately sized image from the given url.
 @param url Url from which the image will be loaded if it's not available in the cache.
 @param placeholderImage Image to be used as a placeholder until the requested image is ready. The placeholder image will only be used if the requested image is not available in the memory cache. If nil, the image view will not change its image until the requested image is ready.
 @param failureBlock Block to be called if an error occurs. The most likely cause of error is that the given path does not contain an image.
 @discussion Retrieves an appropiately sized image (based on the bounds and contentMode of the UIImageView) from the memory or disk cache. Disk access is performed in background. If not cached, loads the original image from the given url, produces an appropiately sized image and caches the result, everything in background.
 @discussion If the requested image is available in the memory cache it will be set synchronously and without animation. In any other case, the image will be set with a short fade animation once its ready.
 @discussion If needed, the least recently used images in the cache will be evicted in background.
 **/
- (void)hnk_setImageFromURL:(NSURL*)url placeholderImage:(UIImage*)placeholderImage failure:(void (^)(NSError *error))failureBlock;

/** Resizes, displays and caches an appropiately sized image from the given image.
 **/
- (void)hnk_setImage:(UIImage*)image withKey:(NSString*)key;

/** Loads, resizes, displays and caches an appropiately sized image from the given entity.
 **/
 - (void)hnk_setImageFromEntity:(id<HNKCacheEntity>)entity;

/**
 Cancels the current image request, if any. 
 @discussion It is recommended to call this from [UITableViewCell prepareForReuse] or [UICollectionViewCell prepareForReuse], or as soon as you don't need the image view anymore.
 **/
- (void)hnk_cancelImageRequest;

@property (nonatomic, strong) HNKCacheFormat *hnk_cacheFormat;

@end

enum
{
    HNKErrorImageFromURLMissingData = -400,
};
