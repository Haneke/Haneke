//
//  HNKCache.h
//  Haneke
//
//  Created by Hermes Pique on 10/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <UIKit/UIKit.h>

@protocol HNKFetcher;
@class HNKCacheFormat;

#if HANEKE_DEBUG
#define HanekeLog(...) NSLog(@"HANEKE: %@", [NSString stringWithFormat:__VA_ARGS__]);
#else
#define HanekeLog(...)
#endif

/**
 A cache for images.
 */
@interface HNKCache : NSObject

#pragma mark Initializing the cache
///---------------------------------------------
/// @name Initializing the cache
///---------------------------------------------

/**
 Initializes a cache with the given name.
 @param name Name of the cache. Used as the name for the subdirectory of the disk cache.
*/
- (id)initWithName:(NSString*)name;

/**
 Returns the shared cache used by the UIKit categories.
 @discussion It is recommended to use the shared cache unless you need separate caches.
 */
+ (HNKCache*)sharedCache;

/**
 Registers a format in the cache. If a format with the same name already exists in the cache, it will be cleared first.
 @param Format to be registered in the cache.
 @discussion If the format preload policy allows it, Haneke will add some or all images cached on disk to the memory cache. If an image of the given format is requested, Haneke will cancel preloading to give priority to the request.
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
 Retrieves an image from the cache, or creates one if it doesn't exist. If the image exists in the memory cache, the success block will be executed synchronously. If the image has to be retreived from the disk cache or has to be created, the success block will be executed asynchronously.
 @param fetcher Fetcher that can provide the original image. If the image doesn't exist in the cache, the fetcher will be asked to provide the original image to add it. Any calls to the fetcher will be done in the main queue.
 @param formatName Name of the format in which the image is desired. The format must have been previously registered with the cache. If the image doesn't exist in the cache, it will be created based on the format. If by creating the image the format disk capacity is surpassed, the least recently used images of the format will be removed until it isn't.
 @param successBlock Block to be called with the requested image. Always called from the main queue. Will be called synchronously if the image exists in the memory cache, or asynchronously if the image has to be retreived from the disk cache or has to be created.
 @param failureBlock Block to be called if the image is not in the cache and the fetcher fails to provide the original. Called asynchronously from the main queue.
 @return YES if image exists in the memory cache (and thus, the success block was called synchronously), NO otherwise.
 */
- (BOOL)fetchImageForFetcher:(id<HNKFetcher>)fetcher formatName:(NSString *)formatName success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;

/**
 Retrieves an image from the cache. If the image exists in the memory cache, the success block will be executed synchronously. If the image has to be retreived from the disk cache, the success block will be executed asynchronously.
 @param key Image cache key.
 @param formatName Name of the format in which the image is desired. The format must have been previously registered with the cache.
 @param successBlock Block to be called with the requested image. Always called from the main queue. Will be called synchronously if the image exists in the memory cache, or asynchronously if the image has to be retreived from the disk cache.
 @param failureBlock Block to be called if the image is not in the cache or if there is another error. Called asynchronously from the main queue. 
 @return YES if image exists in the memory cache (and thus, the success block was called synchronously), NO otherwise.
 */
- (BOOL)fetchImageForKey:(NSString*)key formatName:(NSString *)formatName success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;

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

/**
 Removes all cached images.
 */
- (void)removeAllImages;

/** Removes all cached images of the given format.
 @param formatName Name of the format whose images will be removed.
 */
- (void)removeImagesOfFormatNamed:(NSString*)formatName;

/** Removes all cached images for the given key.
 @param key Key whose images will be removed.
 */
- (void)removeImagesForKey:(NSString*)key;

@end

/** Fetches an image asynchronously. Used by the cache to fetch the original image from which resized images will be created.
 */
@protocol HNKFetcher <NSObject>

/** 
 Returns the key of the original image returned by the fetcher.
 @discussion If two different fetchers provide the same image, they should return the same key for better performance.
 */
@property (nonatomic, readonly) NSString *key;

/**
 Retrieves the original image associated with the fetcher.
 @param successBlock Block to be called with the original image. Must be called from the main queue.
 @param failureBlock Block to be called if the fetcher fails to provide the original image. Must be called from the main queue.
 @discussion If the fetch is cancelled the fetcher must not call any of the provided blocks.
 @see cancelFetch
 */
- (void)fetchImageWithSuccess:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;

@optional

/**
 Cancels the current fetch. When a fetch is cancelled it should not call any of the provided blocks.
 @discussion This will be typically used by UI logic to cancel fetches during view reuse.
 */
- (void)cancelFetch;

@end

typedef NS_ENUM(NSInteger, HNKScaleMode)
{
    HNKScaleModeFill = UIViewContentModeScaleToFill,
    HNKScaleModeAspectFit = UIViewContentModeScaleAspectFit,
    HNKScaleModeAspectFill = UIViewContentModeScaleAspectFill,
    HNKScaleModeNone
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
 @discussion Has no effect if the scale mode is HNKScaleModeNone.
 */
@property (nonatomic, assign) BOOL allowUpscaling;

/**
 The quality of the resulting JPEG image, expressed as a value from 0.0 to 1.0. The value 0.0 represents the maximum compression (or lowest quality) while the value 1.0 represents the least compression (or best quality). 1.0 by default.
 @discussion Only affects opaque images.
 */
@property (nonatomic, assign) CGFloat compressionQuality;

/**
 Format name. Used by Haneke as the format subdirectory name of the disk cache and to uniquely identify the disk queue of the format. Avoid special characters.
 */
@property (nonatomic, readonly) NSString *name;

/**
 Format image size. Images will be scaled to fit or fill this size or ignore it based on scaleMode.
 @discussion Has no effect if the scale mode is HNKScaleModeNone.
 */
@property (nonatomic, assign) CGSize size;

/**
 Format scale mode. Determines if images will fit or fill the format size or not. HNKScaleModeFill by default.
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

/**
 Block to be called before an image is resized. The returned image will be resized. nil by default.
 @warning The block will be called only if the requested image is not found in the cache.
 @warning The block will be called in background when using the asynchronous methods of the cache.
 */
@property (nonatomic, copy) UIImage* (^preResizeBlock)(NSString *key, UIImage *image);

/**
 Block to be called after an image is resized. The returned image will be used by the cache. nil by default.
 @warning The block will be called only if the requested image is not found in the cache.
 @warning The block will be called in background when using the asynchronous methods of the cache.
 */
@property (nonatomic, copy) UIImage* (^postResizeBlock)(NSString *key, UIImage *image);

/** Initializes a format with the given name.
 @param name Name of the format.
 */
- (id)initWithName:(NSString*)name;

/**
 Resized the given image based on the format. Used by the cache to create its images.
 @param image Image to resize.
 @return A resized image based on the format.
 */
- (UIImage*)resizedImageFromImage:(UIImage*)image;

@end

/**
 Haneke error domain. All errors returned by the cache will have this domain.
 */
extern NSString *const HNKErrorDomain;

/**
 Extended file attribute used to associate a key with the file saved on disk.
 */
extern NSString *const HNKExtendedFileAttributeKey;

enum
{
    HNKErrorImageNotFound = -100,
    
    HNKErrorFetcherMustReturnImage = -200,

    HNKErrorDiskCacheCannotReadImageFromData = -300
};
