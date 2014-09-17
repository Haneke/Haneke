//
//  UIButton+Haneke.m
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

#import "UIButton+Haneke.h"
#import "UIView+Haneke.h"
#import "HNKSimpleFetcher.h"
#import "HNKDiskFetcher.h"
#import "HNKNetworkFetcher.h"
#import <objc/runtime.h>

@implementation UIButton (Haneke)

#pragma mark Setting the content image

- (void)hnk_setImageFromURL:(NSURL*)URL forState:(UIControlState)state
{
    [self hnk_setImageFromURL:URL forState:state placeholder:nil];
}

- (void)hnk_setImageFromURL:(NSURL*)URL forState:(UIControlState)state placeholder:(UIImage*)placeholder
{
    [self hnk_setImageFromURL:URL forState:state placeholder:placeholder success:nil failure:nil];
}

- (void)hnk_setImageFromURL:(NSURL*)URL forState:(UIControlState)state placeholder:(UIImage*)placeholder success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    id<HNKFetcher> entity = [[HNKNetworkFetcher alloc] initWithURL:URL];
    [self hnk_setImageFromEntity:entity forState:state placeholder:placeholder success:successBlock failure:failureBlock];
}

- (void)hnk_setImageFromFile:(NSString*)path forState:(UIControlState)state
{
    [self hnk_setImageFromFile:path forState:state placeholder:nil];
}

- (void)hnk_setImageFromFile:(NSString*)path forState:(UIControlState)state placeholder:(UIImage*)placeholder
{
    [self hnk_setImageFromFile:path forState:state placeholder:placeholder success:nil failure:nil];
}

- (void)hnk_setImageFromFile:(NSString*)path forState:(UIControlState)state placeholder:(UIImage*)placeholder success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    id<HNKFetcher> entity = [[HNKDiskFetcher alloc] initWithPath:path];
    [self hnk_setImageFromEntity:entity forState:state placeholder:placeholder success:successBlock failure:failureBlock];
}

- (void)hnk_setImage:(UIImage*)image withKey:(NSString*)key forState:(UIControlState)state
{
    [self hnk_setImage:image withKey:key forState:state placeholder:nil];
}

- (void)hnk_setImage:(UIImage*)image withKey:(NSString*)key forState:(UIControlState)state placeholder:(UIImage*)placeholder
{
    [self hnk_setImage:image withKey:key forState:state placeholder:placeholder success:nil failure:nil];
}

- (void)hnk_setImage:(UIImage*)image withKey:(NSString*)key forState:(UIControlState)state placeholder:(UIImage*)placeholder success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    id<HNKFetcher> entity = [[HNKSimpleFetcher alloc] initWithKey:key image:image];
    [self hnk_setImageFromEntity:entity forState:state placeholder:placeholder success:successBlock failure:failureBlock];
}

- (void)hnk_setImageFromEntity:(id<HNKFetcher>)entity forState:(UIControlState)state
{
    [self hnk_setImageFromEntity:entity forState:state placeholder:nil];
}

- (void)hnk_setImageFromEntity:(id<HNKFetcher>)entity forState:(UIControlState)state placeholder:(UIImage*)placeholder
{
    [self hnk_setImageFromEntity:entity forState:state placeholder:placeholder success:nil failure:nil];
}

- (void)hnk_setImageFromEntity:(id<HNKFetcher>)entity forState:(UIControlState)state placeholder:(UIImage*)placeholder success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    [self hnk_cancelSetImage];
    self.hnk_imageEntity = entity;
    const BOOL didSetImage = [self hnk_fetchImageFromEntity:entity forState:state success:successBlock failure:failureBlock];
    if (!didSetImage && placeholder != nil)
    {
        [self setImage:placeholder forState:state];
    }
}

- (void)hnk_cancelSetImage
{
    id<HNKFetcher> entity = self.hnk_imageEntity;
    if ([entity respondsToSelector:@selector(cancelFetch)])
    {
        [entity cancelFetch];
    }
    self.hnk_imageEntity = nil;
}

- (void)setHnk_imageFormat:(HNKCacheFormat *)cacheFormat
{
    [HNKCache registerSharedFormat:cacheFormat];
    objc_setAssociatedObject(self, @selector(hnk_imageFormat), cacheFormat, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.contentMode = (UIViewContentMode)cacheFormat.scaleMode;
}

- (HNKCacheFormat*)hnk_imageFormat
{
    HNKCacheFormat *format = (HNKCacheFormat *)objc_getAssociatedObject(self, @selector(hnk_imageFormat));
    if (format) return format;
    
    const CGRect bounds = self.bounds;
    NSAssert(bounds.size.width > 0 && bounds.size.height > 0, @"%s: UIButton size is zero. Set its frame, call sizeToFit or force layout first.", __PRETTY_FUNCTION__);
    
    const CGRect contentRect = [self contentRectForBounds:bounds];
    // Ideally we would use imageRectForContentRect: but it requires the image to be set to work
    const UIEdgeInsets imageInsets = self.imageEdgeInsets;
    const CGSize contentSize = contentRect.size;
    const CGSize imageSize = CGSizeMake(contentSize.width - imageInsets.left - imageInsets.right, contentSize.height - imageInsets.top - imageInsets.bottom);
    
    const HNKScaleMode scaleMode = self.contentHorizontalAlignment != UIControlContentHorizontalAlignmentFill || self.contentVerticalAlignment != UIControlContentVerticalAlignmentFill ? HNKScaleModeAspectFit : HNKScaleModeFill;
    
    format = [HNKCache sharedFormatWithSize:imageSize scaleMode:scaleMode];
    if (scaleMode == HNKScaleModeAspectFit)
    {
        format.allowUpscaling = NO;
    }
    
    return format;
}

#pragma mark Private (content image)

- (BOOL)hnk_fetchImageFromEntity:(id<HNKFetcher>)entity forState:(UIControlState)state success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    HNKCacheFormat *format = self.hnk_imageFormat;
    __block BOOL animated = NO;
    __weak __typeof__(self) weakSelf = self;
    const BOOL didSetImage = [[HNKCache sharedCache] fetchImageForEntity:entity formatName:format.name success:^(UIImage *image) {
        __typeof__(weakSelf) strongSelf = weakSelf;
        if ([strongSelf hnk_shouldCancelSetImageForKey:entity.cacheKey]) return;

        [strongSelf hnk_setImage:image forState:state animated:animated success:successBlock];
    } failure:^(NSError *error) {
        __typeof__(weakSelf) strongSelf = weakSelf;
        if ([strongSelf hnk_shouldCancelSetImageForKey:entity.cacheKey]) return;
        
        strongSelf.hnk_imageEntity = nil;
        
        if (failureBlock) failureBlock(error);
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

- (id<HNKFetcher>)hnk_imageEntity
{
    return (id<HNKFetcher>)objc_getAssociatedObject(self, @selector(hnk_imageEntity));
}

- (void)setHnk_imageEntity:(id<HNKFetcher>)entity
{
    objc_setAssociatedObject(self, @selector(hnk_imageEntity), entity, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark Setting the background image

- (void)hnk_setBackgroundImageFromURL:(NSURL*)URL forState:(UIControlState)state
{
    [self hnk_setBackgroundImageFromURL:URL forState:state placeholder:nil];
}

- (void)hnk_setBackgroundImageFromURL:(NSURL*)URL forState:(UIControlState)state placeholder:(UIImage*)placeholder
{
    [self hnk_setBackgroundImageFromURL:URL forState:state placeholder:placeholder success:nil failure:nil];
}

- (void)hnk_setBackgroundImageFromURL:(NSURL*)URL forState:(UIControlState)state placeholder:(UIImage*)placeholder success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    id<HNKFetcher> entity = [[HNKNetworkFetcher alloc] initWithURL:URL];
    [self hnk_setBackgroundImageFromEntity:entity forState:state placeholder:placeholder success:successBlock failure:failureBlock];
}

- (void)hnk_setBackgroundImageFromFile:(NSString*)path forState:(UIControlState)state
{
    [self hnk_setBackgroundImageFromFile:path forState:state placeholder:nil];
}

- (void)hnk_setBackgroundImageFromFile:(NSString*)path forState:(UIControlState)state placeholder:(UIImage*)placeholder
{
    [self hnk_setBackgroundImageFromFile:path forState:state placeholder:placeholder success:nil failure:nil];
}

- (void)hnk_setBackgroundImageFromFile:(NSString*)path forState:(UIControlState)state placeholder:(UIImage*)placeholder success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    id<HNKFetcher> entity = [[HNKDiskFetcher alloc] initWithPath:path];
    [self hnk_setBackgroundImageFromEntity:entity forState:state placeholder:placeholder success:successBlock failure:failureBlock];
}

- (void)hnk_setBackgroundImage:(UIImage*)image withKey:(NSString*)key forState:(UIControlState)state placeholder:(UIImage*)placeholder success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    id<HNKFetcher> entity = [[HNKSimpleFetcher alloc] initWithKey:key image:image];
    [self hnk_setBackgroundImageFromEntity:entity forState:state placeholder:placeholder success:successBlock failure:failureBlock];
}

- (void)hnk_setBackgroundImage:(UIImage*)image withKey:(NSString*)key forState:(UIControlState)state
{
    [self hnk_setBackgroundImage:image withKey:key forState:state placeholder:nil];
}

- (void)hnk_setBackgroundImage:(UIImage*)image withKey:(NSString*)key forState:(UIControlState)state placeholder:(UIImage*)placeholder
{
    [self hnk_setBackgroundImage:image withKey:key forState:state placeholder:placeholder success:nil failure:nil];
}

- (void)hnk_setBackgroundImageFromEntity:(id<HNKFetcher>)entity forState:(UIControlState)state
{
    [self hnk_setBackgroundImageFromEntity:entity forState:state placeholder:nil];
}

- (void)hnk_setBackgroundImageFromEntity:(id<HNKFetcher>)entity forState:(UIControlState)state placeholder:(UIImage*)placeholder
{
    [self hnk_setBackgroundImageFromEntity:entity forState:state placeholder:placeholder success:nil failure:nil];
}

- (void)hnk_setBackgroundImageFromEntity:(id<HNKFetcher>)entity forState:(UIControlState)state placeholder:(UIImage*)placeholder success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    [self hnk_cancelSetBackgroundImage];
    self.hnk_backgroundImageEntity = entity;
    const BOOL didSetImage = [self hnk_fetchBackgroundImageFromEntity:entity forState:state success:successBlock failure:failureBlock];
    if (!didSetImage && placeholder != nil)
    {
        [self setBackgroundImage:placeholder forState:state];
    }
}

- (void)hnk_cancelSetBackgroundImage
{
    id<HNKFetcher> entity = self.hnk_backgroundImageEntity;
    if ([entity respondsToSelector:@selector(cancelFetch)])
    {
        [entity cancelFetch];
    }
    self.hnk_backgroundImageEntity = nil;
}

- (void)setHnk_backgroundImageFormat:(HNKCacheFormat *)cacheFormat
{
    [HNKCache registerSharedFormat:cacheFormat];
    objc_setAssociatedObject(self, @selector(hnk_backgroundImageFormat), cacheFormat, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (HNKCacheFormat*)hnk_backgroundImageFormat
{
    HNKCacheFormat *format = (HNKCacheFormat *)objc_getAssociatedObject(self, @selector(hnk_backgroundImageFormat));
    if (format) return format;
    
    const CGRect bounds = self.bounds;
    NSAssert(bounds.size.width > 0 && bounds.size.height > 0, @"%s: UIButton size is zero. Set its frame, call sizeToFit or force layout first.", __PRETTY_FUNCTION__);
    
    const CGRect backgroundRect = [self backgroundRectForBounds:bounds];
    const CGSize imageSize = backgroundRect.size;
    
    format = [HNKCache sharedFormatWithSize:imageSize scaleMode:HNKScaleModeFill];
    return format;
}

#pragma mark Private (background image)

- (BOOL)hnk_fetchBackgroundImageFromEntity:(id<HNKFetcher>)entity forState:(UIControlState)state success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    HNKCacheFormat *format = self.hnk_backgroundImageFormat;
    __block BOOL animated = NO;
    __weak __typeof__(self) weakSelf = self;
    const BOOL didSetImage = [[HNKCache sharedCache] fetchImageForEntity:entity formatName:format.name success:^(UIImage *image) {
        __typeof__(weakSelf) strongSelf = weakSelf;
        if ([strongSelf hnk_shouldCancelSetBackgroundImageForKey:entity.cacheKey]) return;

        [strongSelf hnk_setBackgroundImage:image forState:state animated:animated success:successBlock];
    } failure:^(NSError *error) {
        __typeof__(weakSelf) strongSelf = weakSelf;
        if ([strongSelf hnk_shouldCancelSetBackgroundImageForKey:entity.cacheKey]) return;

        strongSelf.hnk_backgroundImageEntity = nil;
        
        if (failureBlock) failureBlock(error);
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

- (id<HNKFetcher>)hnk_backgroundImageEntity
{
    return (id<HNKFetcher>)objc_getAssociatedObject(self, @selector(hnk_backgroundImageEntity));
}

- (void)setHnk_backgroundImageEntity:(id<HNKFetcher>)entity
{
    objc_setAssociatedObject(self, @selector(hnk_backgroundImageEntity), entity, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
