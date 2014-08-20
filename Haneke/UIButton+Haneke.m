//
//  UIButton+Haneke.m
//  Haneke
//
//  Created by Hermes Pique on 8/20/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "UIButton+Haneke.h"
#import "UIView+Haneke.h"
#import "HNKSimpleEntity.h"
#import "HNKDiskEntity.h"
#import "HNKNetworkEntity.h"
#import <objc/runtime.h>

@implementation UIButton (Haneke)

#pragma mark Setting the content image

- (void)hnk_setImageFromURL:(NSURL*)URL forState:(UIControlState)state
{
    [self hnk_setImageFromURL:URL forState:state placeholderImage:nil];
}

- (void)hnk_setImageFromURL:(NSURL*)URL forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage
{
    [self hnk_setImageFromURL:URL forState:state placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)hnk_setImageFromURL:(NSURL*)URL forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    id<HNKCacheEntity> entity = [[HNKNetworkEntity alloc] initWithURL:URL];
    [self hnk_setImageFromEntity:entity forState:state placeholderImage:placeholderImage success:successBlock failure:failureBlock];
}

- (void)hnk_setImageFromFile:(NSString*)path forState:(UIControlState)state
{
    [self hnk_setImageFromFile:path forState:state placeholderImage:nil];
}

- (void)hnk_setImageFromFile:(NSString*)path forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage
{
    [self hnk_setImageFromFile:path forState:state placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)hnk_setImageFromFile:(NSString*)path forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    id<HNKCacheEntity> entity = [[HNKDiskEntity alloc] initWithPath:path];
    [self hnk_setImageFromEntity:entity forState:state placeholderImage:placeholderImage success:successBlock failure:failureBlock];
}

- (void)hnk_setImage:(UIImage*)image withKey:(NSString*)key forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    id<HNKCacheEntity> entity = [[HNKSimpleEntity alloc] initWithKey:key image:image];
    [self hnk_setImageFromEntity:entity forState:state placeholderImage:placeholderImage success:successBlock failure:failureBlock];
}

- (void)hnk_setImageFromEntity:(id<HNKCacheEntity>)entity forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    [self hnk_cancelSetImage];
    self.hnk_imageEntity = entity;
    const BOOL didSetImage = [self hnk_fetchImageFromEntity:entity forState:state success:successBlock failure:failureBlock];
    if (!didSetImage && placeholderImage != nil)
    {
        [self setImage:placeholderImage forState:state];
    }
}

- (void)hnk_cancelSetImage
{
    id<HNKCacheEntity> entity = self.hnk_imageEntity;
    if ([entity respondsToSelector:@selector(cancelFetch)])
    {
        [entity cancelFetch];
    }
    self.hnk_imageEntity = nil;
}

- (void)setHnk_imageCacheFormat:(HNKCacheFormat *)cacheFormat
{
    [self hnk_registerFormat:cacheFormat];
    objc_setAssociatedObject(self, @selector(hnk_imageCacheFormat), cacheFormat, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.contentMode = (UIViewContentMode)cacheFormat.scaleMode;
}

- (HNKCacheFormat*)hnk_imageCacheFormat
{
    HNKCacheFormat *format = (HNKCacheFormat *)objc_getAssociatedObject(self, @selector(hnk_imageCacheFormat));
    if (format) return format;
    
    const CGRect bounds = self.bounds;
    NSAssert(bounds.size.width > 0 && bounds.size.height > 0, @"%s: UIButton size is zero. Set its frame, call sizeToFit or force layout first.", __PRETTY_FUNCTION__);
    
    const CGRect contentRect = [self contentRectForBounds:bounds];
    const CGRect imageRect = [self imageRectForContentRect:contentRect];
    const CGSize imageSize = imageRect.size;
    
    HNKScaleMode scaleMode = self.hnk_scaleMode;
    format = [self hnk_sharedFormatWithSize:imageSize scaleMode:scaleMode];
    return format;
}

#pragma mark Private (content image)

- (BOOL)hnk_fetchImageFromEntity:(id<HNKCacheEntity>)entity forState:(UIControlState)state success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    HNKCacheFormat *format = self.hnk_imageCacheFormat;
    __block BOOL animated = NO;
    const BOOL didSetImage = [[HNKCache sharedCache] retrieveImageForEntity:entity formatName:format.name completionBlock:^(UIImage *image, NSError *error) {
        if ([self hnk_shouldCancelSetImageForKey:entity.cacheKey]) return;
        
        if (image)
        {
            [self hnk_setImage:image forState:state animated:animated success:successBlock];
        }
        else
        {
            [self hnk_failSetImageWithError:error failure:failureBlock];
        }
    }];
    animated = YES;
    return didSetImage;
}

- (void)hnk_setImage:(UIImage*)image forState:(UIControlState)state animated:(BOOL)animated success:(void (^)(UIImage *image))successBlock
{
    self.hnk_imageEntity = nil;
    
    if (successBlock)
    {
        successBlock(image);
    }
    else
    {
        const NSTimeInterval duration = animated ? 0.1 : 0;
        [UIView transitionWithView:self duration:duration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [self setImage:image forState:state];
        } completion:nil];
    }
}

- (BOOL)hnk_shouldCancelSetImageForKey:(NSString*)key
{
    if ([self.hnk_imageEntity.cacheKey isEqualToString:key]) return NO;
    
    HanekeLog(@"Cancelled set image from key %@", key.lastPathComponent);
    return YES;
}

- (void)hnk_failSetImageWithError:(NSError*)error failure:(void (^)(NSError *error))failureBlock
{
    self.hnk_imageEntity = nil;
    
    if (failureBlock) failureBlock(error);
}

- (id<HNKCacheEntity>)hnk_imageEntity
{
    return (id<HNKCacheEntity>)objc_getAssociatedObject(self, @selector(hnk_imageEntity));
}

- (void)setHnk_imageEntity:(id<HNKCacheEntity>)entity
{
    objc_setAssociatedObject(self, @selector(hnk_imageEntity), entity, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark Setting the background image

- (void)hnk_setBackgroundImageFromURL:(NSURL*)URL forState:(UIControlState)state
{
    [self hnk_setBackgroundImageFromURL:URL forState:state placeholderImage:nil];
}

- (void)hnk_setBackgroundImageFromURL:(NSURL*)URL forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage
{
    [self hnk_setBackgroundImageFromURL:URL forState:state placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)hnk_setBackgroundImageFromURL:(NSURL*)URL forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    id<HNKCacheEntity> entity = [[HNKNetworkEntity alloc] initWithURL:URL];
    [self hnk_setBackgroundImageFromEntity:entity forState:state placeholderImage:placeholderImage success:successBlock failure:failureBlock];
}

- (void)hnk_setBackgroundImageFromFile:(NSString*)path forState:(UIControlState)state
{
    [self hnk_setBackgroundImageFromFile:path forState:state placeholderImage:nil];
}

- (void)hnk_setBackgroundImageFromFile:(NSString*)path forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage
{
    [self hnk_setBackgroundImageFromFile:path forState:state placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)hnk_setBackgroundImageFromFile:(NSString*)path forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    id<HNKCacheEntity> entity = [[HNKDiskEntity alloc] initWithPath:path];
    [self hnk_setBackgroundImageFromEntity:entity forState:state placeholderImage:placeholderImage success:successBlock failure:failureBlock];
}

- (void)hnk_setBackgroundImage:(UIImage*)image withKey:(NSString*)key forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    id<HNKCacheEntity> entity = [[HNKSimpleEntity alloc] initWithKey:key image:image];
    [self hnk_setBackgroundImageFromEntity:entity forState:state placeholderImage:placeholderImage success:successBlock failure:failureBlock];
}

- (void)hnk_setBackgroundImageFromEntity:(id<HNKCacheEntity>)entity forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    [self hnk_cancelSetBackgroundImage];
    self.hnk_backgroundImageEntity = entity;
    const BOOL didSetImage = [self hnk_fetchBackgroundImageFromEntity:entity forState:state success:successBlock failure:failureBlock];
    if (!didSetImage && placeholderImage != nil)
    {
        [self setBackgroundImage:placeholderImage forState:state];
    }
}

- (void)hnk_cancelSetBackgroundImage
{
    id<HNKCacheEntity> entity = self.hnk_backgroundImageEntity;
    if ([entity respondsToSelector:@selector(cancelFetch)])
    {
        [entity cancelFetch];
    }
    self.hnk_backgroundImageEntity = nil;
}

- (void)setHnk_backgroundImageCacheFormat:(HNKCacheFormat *)cacheFormat
{
    [self hnk_registerFormat:cacheFormat];
    objc_setAssociatedObject(self, @selector(hnk_backgroundImageCacheFormat), cacheFormat, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (HNKCacheFormat*)hnk_backgroundImageCacheFormat
{
    HNKCacheFormat *format = (HNKCacheFormat *)objc_getAssociatedObject(self, @selector(hnk_backgroundImageCacheFormat));
    if (format) return format;
    
    const CGRect bounds = self.bounds;
    NSAssert(bounds.size.width > 0 && bounds.size.height > 0, @"%s: UIButton size is zero. Set its frame, call sizeToFit or force layout first.", __PRETTY_FUNCTION__);
    
    const CGRect backgroundRect = [self backgroundRectForBounds:bounds];
    const CGSize imageSize = backgroundRect.size;
    
    format = [self hnk_sharedFormatWithSize:imageSize scaleMode:HNKScaleModeFill];
    return format;
}

#pragma mark Private (background image)

- (BOOL)hnk_fetchBackgroundImageFromEntity:(id<HNKCacheEntity>)entity forState:(UIControlState)state success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    HNKCacheFormat *format = self.hnk_backgroundImageCacheFormat;
    __block BOOL animated = NO;
    const BOOL didSetImage = [[HNKCache sharedCache] retrieveImageForEntity:entity formatName:format.name completionBlock:^(UIImage *image, NSError *error) {
        if ([self hnk_shouldCancelSetBackgroundImageForKey:entity.cacheKey]) return;
        
        if (image)
        {
            [self hnk_setBackgroundImage:image forState:state animated:animated success:successBlock];
        }
        else
        {
            [self hnk_failSetBackgroundImageWithError:error failure:failureBlock];
        }
    }];
    animated = YES;
    return didSetImage;
}

- (void)hnk_setBackgroundImage:(UIImage*)image forState:(UIControlState)state animated:(BOOL)animated success:(void (^)(UIImage *image))successBlock
{
    self.hnk_backgroundImageEntity = nil;
    
    if (successBlock)
    {
        successBlock(image);
    }
    else
    {
        const NSTimeInterval duration = animated ? 0.1 : 0;
        [UIView transitionWithView:self duration:duration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [self setBackgroundImage:image forState:state];
        } completion:nil];
    }
}

- (BOOL)hnk_shouldCancelSetBackgroundImageForKey:(NSString*)key
{
    if ([self.hnk_backgroundImageEntity.cacheKey isEqualToString:key]) return NO;
    
    HanekeLog(@"Cancelled set background image from key %@", key.lastPathComponent);
    return YES;
}

- (void)hnk_failSetBackgroundImageWithError:(NSError*)error failure:(void (^)(NSError *error))failureBlock
{
    self.hnk_backgroundImageEntity = nil;
    
    if (failureBlock) failureBlock(error);
}

- (id<HNKCacheEntity>)hnk_backgroundImageEntity
{
    return (id<HNKCacheEntity>)objc_getAssociatedObject(self, @selector(hnk_backgroundImageEntity));
}

- (void)setHnk_backgroundImageEntity:(id<HNKCacheEntity>)entity
{
    objc_setAssociatedObject(self, @selector(hnk_backgroundImageEntity), entity, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
