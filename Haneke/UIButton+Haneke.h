//
//  UIButton+Haneke.h
//  Haneke
//
//  Created by Hermes Pique on 8/20/14.
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
#import "HNKCache.h"

@interface UIButton (Haneke)

#pragma mark Setting the content image

/** Loads, resizes, displays and caches an appropiately sized foreground image from the given url.
 @param url URL from which the image will be loaded if it's not available in the cache.
 @param state Control state that will use the image.
 @see hnk_setImageFromURL:forState:placeholder:success:failure:
 */
- (void)hnk_setImageFromURL:(NSURL*)URL forState:(UIControlState)state;

/** Loads, resizes, displays and caches an appropiately sized foreground image from the given url.
 @param url URL from which the image will be loaded if it's not available in the cache.
 @param state Control state that will use the image.
 @param placeholder Image to be used as a placeholder until the requested image is ready. The placeholder image will only be used if the requested image is not available in the memory cache. If nil, the button will not change its image until the requested image is ready.
 @see hnk_setImageFromURL:forState:placeholder:success:failure:
 */
- (void)hnk_setImageFromURL:(NSURL*)URL forState:(UIControlState)state placeholder:(UIImage*)placeholder;

/** Loads, resizes, displays and caches an appropiately sized foreground image from the given url. If a success block is provided you will be responsible for setting the image.
 @param url URL from which the image will be loaded if it's not available in the cache.
 @param state Control state that will use the image.
 @param placeholder Image to be used as a placeholder until the requested image is ready. The placeholder image will only be used if the requested image is not available in the memory cache. If nil, the button will not change its image until the requested image is ready.
 @param successBlock Block to be called when the requested image is ready to be set. If provided, the block is reponsible for setting the image. Can be nil.
 @param failureBlock Block to be called if an error occurs. Can be nil.
 @discussion Retrieves an appropiately sized image (based on the bounds, insets and content alignment of the button) from the memory or disk cache. Disk access is performed in background. If not cached, loads the original image from the given url, produces an appropiately sized image and caches the result, everything in background.
 @discussion If no success block is provided, the requested image will be set with a short fade transition, or synchronously and without transition when retrieved from the memory cache.
 @discussion If needed, the least recently used images in the cache will be evicted in background.
 @warning If a success block is provided you will be responsible for setting the image.
 */
- (void)hnk_setImageFromURL:(NSURL*)URL forState:(UIControlState)state placeholder:(UIImage*)placeholder success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;

/** Loads, resizes, displays and caches an appropiately sized foreground image from the given path.
 @param path Path from which the image will be loaded if it's not available in the cache.
 @param state Control state that will use the image.
 @see hnk_setImageFromFile:forState:placeholder:success:failure:
 */
- (void)hnk_setImageFromFile:(NSString*)path forState:(UIControlState)state;

/** Loads, resizes, displays and caches an appropiately sized foreground image from the given path.
 @param path Path from which the image will be loaded if it's not available in the cache.
 @param state Control state that will use the image.
 @param placeholder Image to be used as a placeholder until the requested image is ready. The placeholder image will only be used if the requested image is not available in the memory cache. If nil, the button will not change its image until the requested image is ready.
 @see hnk_setImageFromFile:forState:placeholder:success:failure:
 */
- (void)hnk_setImageFromFile:(NSString*)path forState:(UIControlState)state placeholder:(UIImage*)placeholder;

/** Loads, resizes, displays and caches an appropiately sized foreground image from the given path. If a success block is provided you will be responsible for setting the image.
 @param path Path from which the image will be loaded if it's not available in the cache.
 @param state Control state that will use the image.
 @param placeholder Image to be used as a placeholder until the requested image is ready. The placeholder image will only be used if the requested image is not available in the memory cache. If nil, the button will not change its image until the requested image is ready.
 @param successBlock Block to be called when the requested image is ready to be set. If provided, the block is reponsible for setting the image. Can be nil.
 @param failureBlock Block to be called if an error occurs. The most likely cause of error is that the given path does not contain an image. Can be nil.
 @discussion Retrieves an appropiately sized image (based on the bounds, insets and content alignment of the button) from the memory or disk cache. Disk access is performed in background. If not cached, loads the original image from disk, produces an appropiately sized image and caches the result, everything in background.
 @discussion If no success block is provided, the requested image will be set with a short fade transition, or synchronously and without transition when retrieved from the memory cache.
 @discussion If needed, the least recently used images in the cache will be evicted in background.
 @discussion If the success block is nil, the image will be set with a short fade transition, or inmmediatly if the image was retrieved from the memory cache.
 @warning If a success block is provided you will be responsible for setting the image.
 */
- (void)hnk_setImageFromFile:(NSString*)path forState:(UIControlState)state placeholder:(UIImage*)placeholder success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;

/** Resizes, displays and caches an appropiately sized foreground image from the given image.
 @param image Original image.
 @param key A key. Used by the cache to uniquely identify an image.
 @param state Control state that will use the image.
 @see hnk_setImage:withKey:forState:placeholder:success:failure:
 */
- (void)hnk_setImage:(UIImage*)image withKey:(NSString*)key forState:(UIControlState)state;

/** Resizes, displays and caches an appropiately sized foreground image from the given image.
 @param image Original image.
 @param key A key. Used by the cache to uniquely identify an image.
 @param state Control state that will use the image.
 @param placeholder Image to be used as a placeholder until the requested image is ready. The placeholder image will only be used if the requested image is not available in the memory cache. If nil, the button will not change its image until the requested image is ready.
 @see hnk_setImage:withKey:forState:placeholder:success:failure:
 */
- (void)hnk_setImage:(UIImage*)image withKey:(NSString*)key forState:(UIControlState)state placeholder:(UIImage*)placeholder;

/** Resizes, displays and caches an appropiately sized foreground image from the given image. If a success block is provided you will be responsible for setting the image.
 @param image Original image.
 @param key A key. Used by the cache to uniquely identify an image.
 @param state Control state that will use the image.
 @param placeholder Image to be used as a placeholder until the requested image is ready. The placeholder image will only be used if the requested image is not available in the memory cache. If nil, the button will not change its image until the requested image is ready.
 @param successBlock Block to be called when the requested image is ready to be set. If provided, the block is reponsible for setting the image. Can be nil.
 @param failureBlock Block to be called if an error occurs. Highly unlikely for this method. Can be nil.
 @discussion Retrieves an appropiately sized image (based on the bounds, insets and content alignment of the button) from the memory or disk cache. Disk access is performed in background. If not cached, takes the given original image, produces an appropiately sized image and caches the result, everything in background.
 @discussion If no success block is provided, the requested image will be set with a short fade transition, or synchronously and without transition when retrieved from the memory cache.
 @discussion If needed, the least recently used images in the cache will be evicted in background.
 @warning If a success block is provided you will be responsible for setting the image.
 */
- (void)hnk_setImage:(UIImage*)image withKey:(NSString*)key forState:(UIControlState)state placeholder:(UIImage*)placeholder success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;

/** Loads, resizes, displays and caches an appropiately sized foreground image from the given fetcher.
 @param fetcher Fetcher from which the original image will be retrieved if needed. The fetcher will have to provide the original image only if it can't be found in the cache.
 @param state Control state that will use the image.
 @see hnk_setImageFromFetcher:forState:placeholder:success:failure:
 */
- (void)hnk_setImageFromFetcher:(id<HNKFetcher>)fetcher forState:(UIControlState)state;

/** Loads, resizes, displays and caches an appropiately sized foreground image from the given fetcher.
 @param fetcher Fetcher from which the original image will be retrieved if needed. The fetcher will have to provide the original image only if it can't be found in the cache.
 @param state Control state that will use the image.
 @param placeholder Image to be used as a placeholder until the requested image is ready. The placeholder image will only be used if the requested image is not available in the memory cache. If nil, the button will not change its image until the requested image is ready.
 @see hnk_setImageFromFetcher:forState:placeholder:success:failure:
  */
- (void)hnk_setImageFromFetcher:(id<HNKFetcher>)fetcher forState:(UIControlState)state placeholder:(UIImage*)placeholder;

/** Loads, resizes, displays and caches an appropiately sized foreground image from the given fetcher. If a success block is provided you will be responsible for setting the image.
 @param fetcher Fetcher from which the original image will be retrieved if needed. The fetcher will have to provide the original image only if it can't be found in the cache.
 @param state Control state that will use the image.
 @param placeholder Image to be used as a placeholder until the requested image is ready. The placeholder image will only be used if the requested image is not available in the memory cache. If nil, the button will not change its image until the requested image is ready.
 @param successBlock Block to be called when the requested image is ready to be set. If provided, the block is reponsible for setting the image. Can be nil.
 @param failureBlock Block to be called if an error occurs. The most likely cause of error is that the given fetcher failed to provide the original image. Can be nil.
 @discussion Retrieves an appropiately sized image (based on the bounds, insets and content alignment of the button) from the memory or disk cache. Disk access is performed in background. If not cached, fetches the original image from the given fetcher, produces an appropiately sized image and caches the result, everything in background.
 @discussion If no success block is provided, the requested image will be set with a short fade transition, or synchronously and without transition when retrieved from the memory cache.
 @discussion If needed, the least recently used images in the cache will be evicted in background.
 @warning If a success block is provided you will be responsible for setting the image.
 */
- (void)hnk_setImageFromFetcher:(id<HNKFetcher>)fetcher forState:(UIControlState)state placeholder:(UIImage*)placeholder success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;

/**
 Cancels the current set image request, if any.
 @discussion It is recommended to call this from [UITableViewCell prepareForReuse] or [UICollectionViewCell prepareForReuse], or as soon as you don't need the image view anymore.
 */
- (void)hnk_cancelSetImage;

/**
 Cache format used by the button for its foreground images.
 @discussion Each button has a default foreground image format created on demand. The default format size matches the bounds and edge insets of the image view and will scale images based on the content alignment.
 @discussion Modifying the default foreground image format is discouraged. Instead, you can set your own custom format. To apply the same custom format to various buttons you must use the same instance.
 */
@property (nonatomic, strong) HNKCacheFormat *hnk_imageFormat;

#pragma mark Setting the background image

/** Loads, resizes, displays and caches an appropiately sized background image from the given url.
 @param url URL from which the image will be loaded if it's not available in the cache.
 @param state Control state that will use the image.
 @see hnk_setBackgroundImageFromURL:forState:placeholder:success:failure:
 */
- (void)hnk_setBackgroundImageFromURL:(NSURL*)URL forState:(UIControlState)state;

/** Loads, resizes, displays and caches an appropiately sized background image from the given url.
 @param url URL from which the image will be loaded if it's not available in the cache.
 @param state Control state that will use the image.
 @param placeholder Image to be used as a placeholder until the requested image is ready. The placeholder image will only be used if the requested image is not available in the memory cache. If nil, the button will not change its image until the requested image is ready.
 @see hnk_setBackgroundImageFromURL:forState:placeholder:success:failure:
 */
- (void)hnk_setBackgroundImageFromURL:(NSURL*)URL forState:(UIControlState)state placeholder:(UIImage*)placeholder;

/** Loads, resizes, displays and caches an appropiately sized background image from the given url. If a success block is provided you will be responsible for setting the image.
 @param url URL from which the image will be loaded if it's not available in the cache.
 @param state Control state that will use the image.
 @param placeholder Image to be used as a placeholder until the requested image is ready. The placeholder image will only be used if the requested image is not available in the memory cache. If nil, the button will not change its image until the requested image is ready.
 @param successBlock Block to be called when the requested image is ready to be set. If provided, the block is reponsible for setting the image. Can be nil.
 @param failureBlock Block to be called if an error occurs. Can be nil.
 @discussion Retrieves an appropiately sized image (based on the bounds of the button) from the memory or disk cache. Disk access is performed in background. If not cached, loads the original image from the given url, produces an appropiately sized image and caches the result, everything in background.
 @discussion If no success block is provided, the requested image will be set with a short fade transition, or synchronously and without transition when retrieved from the memory cache.
 @discussion If needed, the least recently used images in the cache will be evicted in background.
 @warning If a success block is provided you will be responsible for setting the image.
 */
- (void)hnk_setBackgroundImageFromURL:(NSURL*)URL forState:(UIControlState)state placeholder:(UIImage*)placeholder success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;

/** Loads, resizes, displays and caches an appropiately sized background image from the given path.
 @param path Path from which the image will be loaded if it's not available in the cache.
 @param state Control state that will use the image.
 @see hnk_setBackgroundImageFromFile:forState:placeholder:success:failure:
 */
- (void)hnk_setBackgroundImageFromFile:(NSString*)path forState:(UIControlState)state;

/** Loads, resizes, displays and caches an appropiately sized background image from the given path.
 @param path Path from which the image will be loaded if it's not available in the cache.
 @param state Control state that will use the image.
 @param placeholder Image to be used as a placeholder until the requested image is ready. The placeholder image will only be used if the requested image is not available in the memory cache. If nil, the button will not change its image until the requested image is ready.
 @see hnk_setBackgroundImageFromFile:forState:placeholder:success:failure:
 */
- (void)hnk_setBackgroundImageFromFile:(NSString*)path forState:(UIControlState)state placeholder:(UIImage*)placeholder;

/** Loads, resizes, displays and caches an appropiately sized background image from the given path. If a success block is provided you will be responsible for setting the image.
 @param path Path from which the image will be loaded if it's not available in the cache.
 @param state Control state that will use the image.
 @param placeholder Image to be used as a placeholder until the requested image is ready. The placeholder image will only be used if the requested image is not available in the memory cache. If nil, the button will not change its image until the requested image is ready.
 @param successBlock Block to be called when the requested image is ready to be set. If provided, the block is reponsible for setting the image. Can be nil.
 @param failureBlock Block to be called if an error occurs. The most likely cause of error is that the given path does not contain an image. Can be nil.
 @discussion Retrieves an appropiately sized image (based on the bounds of the button) from the memory or disk cache. Disk access is performed in background. If not cached, loads the original image from disk, produces an appropiately sized image and caches the result, everything in background.
 @discussion If no success block is provided, the requested image will be set with a short fade transition, or synchronously and without transition when retrieved from the memory cache.
 @discussion If needed, the least recently used images in the cache will be evicted in background.
 @discussion If the success block is nil, the image will be set with a short fade transition, or inmmediatly if the image was retrieved from the memory cache.
 @warning If a success block is provided you will be responsible for setting the image.
 */
- (void)hnk_setBackgroundImageFromFile:(NSString*)path forState:(UIControlState)state placeholder:(UIImage*)placeholder success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;

/** Resizes, displays and caches an appropiately sized background image from the given image.
 @param image Original image.
 @param key A key. Used by the cache to uniquely identify an image.
 @param state Control state that will use the image.
 @see hnk_setBackgroundImage:withKey:forState:placeholder:success:failure:
 */
- (void)hnk_setBackgroundImage:(UIImage*)image withKey:(NSString*)key forState:(UIControlState)state;

/** Resizes, displays and caches an appropiately sized background image from the given image.
 @param image Original image.
 @param key A key. Used by the cache to uniquely identify an image.
 @param state Control state that will use the image.
 @param placeholder Image to be used as a placeholder until the requested image is ready. The placeholder image will only be used if the requested image is not available in the memory cache. If nil, the button will not change its image until the requested image is ready.
 @see hnk_setBackgroundImage:withKey:forState:placeholder:success:failure:
 */
- (void)hnk_setBackgroundImage:(UIImage*)image withKey:(NSString*)key forState:(UIControlState)state placeholder:(UIImage*)placeholder;

/** Resizes, displays and caches an appropiately sized background image from the given image. If a success block is provided you will be responsible for setting the image.
 @param image Original image.
 @param key A key. Used by the cache to uniquely identify an image.
 @param state Control state that will use the image.
 @param placeholder Image to be used as a placeholder until the requested image is ready. The placeholder image will only be used if the requested image is not available in the memory cache. If nil, the button will not change its image until the requested image is ready.
 @param successBlock Block to be called when the requested image is ready to be set. If provided, the block is reponsible for setting the image. Can be nil.
 @param failureBlock Block to be called if an error occurs. Highly unlikely for this method. Can be nil.
 @discussion Retrieves an appropiately sized image (based on the bounds of the button) from the memory or disk cache. Disk access is performed in background. If not cached, takes the given original image, produces an appropiately sized image and caches the result, everything in background.
 @discussion If no success block is provided, the requested image will be set with a short fade transition, or synchronously and without transition when retrieved from the memory cache.
 @discussion If needed, the least recently used images in the cache will be evicted in background.
 @warning If a success block is provided you will be responsible for setting the image.
 */
- (void)hnk_setBackgroundImage:(UIImage*)image withKey:(NSString*)key forState:(UIControlState)state placeholder:(UIImage*)placeholder success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;

/** Loads, resizes, displays and caches an appropiately sized background image from the given fetcher.
 @param fetcher Fetcher from which the original image will be retrieved if needed. The fetcher will have to provide the original image only if it can't be found in the cache.
 @param state Control state that will use the image.
 @see hnk_setBackgroundImageFromFetcher:forState:placeholder:success:failure:
 */
- (void)hnk_setBackgroundImageFromFetcher:(id<HNKFetcher>)fetcher forState:(UIControlState)state;

/** Loads, resizes, displays and caches an appropiately sized background image from the given fetcher.
 @param fetcher Fetcher from which the original image will be retrieved if needed. The fetcher will have to provide the original image only if it can't be found in the cache.
 @param state Control state that will use the image.
 @param placeholder Image to be used as a placeholder until the requested image is ready. The placeholder image will only be used if the requested image is not available in the memory cache. If nil, the button will not change its image until the requested image is ready.
 @see hnk_setBackgroundImageFromFetcher:forState:placeholder:success:failure:
 */
- (void)hnk_setBackgroundImageFromFetcher:(id<HNKFetcher>)fetcher forState:(UIControlState)state placeholder:(UIImage*)placeholder;

/** Loads, resizes, displays and caches an appropiately sized background image from the given fetcher. If a success block is provided you will be responsible for setting the image.
 @param fetcher Fetcher from which the original image will be retrieved if needed. The fetcher will have to provide the original image only if it can't be found in the cache.
 @param state Control state that will use the image.
 @param placeholder Image to be used as a placeholder until the requested image is ready. The placeholder image will only be used if the requested image is not available in the memory cache. If nil, the button will not change its image until the requested image is ready.
 @param successBlock Block to be called when the requested image is ready to be set. If provided, the block is reponsible for setting the image. Can be nil.
 @param failureBlock Block to be called if an error occurs. The most likely cause of error is that the given fetcher failed to provide the original image. Can be nil.
 @discussion Retrieves an appropiately sized image (based on the bounds of the button) from the memory or disk cache. Disk access is performed in background. If not cached, fetches the original image from the given fetcher, produces an appropiately sized image and caches the result, everything in background.
 @discussion If no success block is provided, the requested image will be set with a short fade transition, or synchronously and without transition when retrieved from the memory cache.
 @discussion If needed, the least recently used images in the cache will be evicted in background.
 @warning If a success block is provided you will be responsible for setting the image.
 */
- (void)hnk_setBackgroundImageFromFetcher:(id<HNKFetcher>)fetcher forState:(UIControlState)state placeholder:(UIImage*)placeholder success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;

/**
 Cancels the current set background image request, if any.
 @discussion It is recommended to call this from [UITableViewCell prepareForReuse] or [UICollectionViewCell prepareForReuse], or as soon as you don't need the image view anymore.
 */
- (void)hnk_cancelSetBackgroundImage;

/**
 Cache format used by the button for its background images.
 @discussion Each button has a default background image format created on demand. The default format size matches the bounds the image view and will scale images to fill.
 @discussion Modifying the default background image format is discouraged. Instead, you can set your own custom format. To apply the same custom format to various buttons you must use the same instance.
 */
@property (nonatomic, strong) HNKCacheFormat *hnk_backgroundImageFormat;

@end
