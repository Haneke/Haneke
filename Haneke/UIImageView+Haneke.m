//
//  UIImageView+Haneke.m
//  Haneke
//
//  Created by Hermes Pique on 12/02/14.
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

#import "UIImageView+Haneke.h"
#import "HNKDiskEntity.h"
#import "HNKSimpleEntity.h"
#import "HNKNetworkEntity.h"
#import <objc/runtime.h>

static NSString *NSStringFromHNKScaleMode(HNKScaleMode scaleMode)
{
    switch (scaleMode) {
        case HNKScaleModeFill:
            return @"fill";
        case HNKScaleModeAspectFill:
            return @"aspectfill";
        case HNKScaleModeAspectFit:
            return @"aspectfit";
        case HNKScaleModeNone:
            return @"scalenone";
    }
    return nil;
}

@implementation UIImageView (Haneke)

- (void)hnk_setImageFromFile:(NSString*)path
{
    [self hnk_setImageFromFile:path placeholderImage:nil success:nil failure:nil];
}

- (void)hnk_setImageFromFile:(NSString*)path placeholderImage:(UIImage *)placeholderImage
{
    [self hnk_setImageFromFile:path placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)hnk_setImageFromFile:(NSString*)path success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *))failureBlock
{
    [self hnk_setImageFromFile:path placeholderImage:nil success:successBlock failure:failureBlock];
}

- (void)hnk_setImageFromFile:(NSString*)path placeholderImage:(UIImage*)placeholderImage success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    [self hnk_cancelImageRequest];
    self.hnk_requestedCacheKey = path;
    HNKCacheFormat *format = self.hnk_cacheFormat;
    NSString *formatName = format.name;
    __block BOOL animated = NO;
    const BOOL didSetImage = [[HNKCache sharedCache] retrieveImageForKey:path formatName:format.name completionBlock:^(UIImage *image, NSError *error) {
        if ([self hnk_shouldCancelRequestForKey:path formatName:formatName]) return;
        
        if (image)
        {
            [self hnk_setImage:image animated:animated success:successBlock];
            return;
        }
        
        id<HNKCacheEntity> entity = [[HNKDiskEntity alloc] initWithPath:path];
        self.hnk_entity = entity;
        [self hnk_retrieveImageFromEntity:entity success:successBlock failure:failureBlock];
    }];
    animated = YES;
    if (!didSetImage && placeholderImage != nil)
    {
        self.image = placeholderImage;
    }
}

- (void)hnk_setImageFromURL:(NSURL*)url
{
    [self hnk_setImageFromURL:url placeholderImage:nil success:nil failure:nil];
}

- (void)hnk_setImageFromURL:(NSURL*)url placeholderImage:(UIImage *)placeholderImage
{
    [self hnk_setImageFromURL:url placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)hnk_setImageFromURL:(NSURL*)url success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    [self hnk_setImageFromURL:url placeholderImage:nil success:successBlock failure:failureBlock];
}

- (void)hnk_setImageFromURL:(NSURL*)url placeholderImage:(UIImage*)placeholderImage success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    [self hnk_cancelImageRequest];
    NSString *absoluteString = url.absoluteString;
    self.hnk_requestedCacheKey = absoluteString;
    HNKCacheFormat *format = self.hnk_cacheFormat;
    NSString *formatName = format.name;
    __block BOOL animated = NO;
    const BOOL didSetImage = [[HNKCache sharedCache] retrieveImageForKey:absoluteString formatName:format.name completionBlock:^(UIImage *image, NSError *error)
    {
        if ([self hnk_shouldCancelRequestForKey:absoluteString formatName:formatName]) return;
        
        if (image)
        {
            [self hnk_setImage:image animated:animated success:successBlock];
            return;
        }
        
        id<HNKCacheEntity> entity = [[HNKNetworkEntity alloc] initWithURL:url];
        self.hnk_entity = entity;
        [self hnk_retrieveImageFromEntity:entity success:successBlock failure:failureBlock];
    }];
    animated = YES;
    if (!didSetImage && placeholderImage != nil)
    {
        self.image = placeholderImage;
    }
}

- (void)hnk_setImage:(UIImage*)originalImage withKey:(NSString*)key
{
    [self hnk_setImage:originalImage withKey:key placeholderImage:nil success:nil failure:nil];
}

- (void)hnk_setImage:(UIImage*)originalImage withKey:(NSString*)key placeholderImage:(UIImage*)placeholderImage
{
    [self hnk_setImage:originalImage withKey:key placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)hnk_setImage:(UIImage*)originalImage withKey:(NSString*)key success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    [self hnk_setImage:originalImage withKey:key placeholderImage:nil success:successBlock failure:failureBlock];
}

- (void)hnk_setImage:(UIImage*)originalImage withKey:(NSString*)key placeholderImage:(UIImage*)placeholderImage success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    id<HNKCacheEntity> entity = [[HNKSimpleEntity alloc] initWithKey:key image:originalImage];
    [self hnk_setImageFromEntity:entity placeholderImage:placeholderImage success:successBlock failure:failureBlock];
}

- (void)hnk_setImageFromEntity:(id<HNKCacheEntity>)entity
{
    [self hnk_setImageFromEntity:entity placeholderImage:nil success:nil failure:nil];
}

- (void)hnk_setImageFromEntity:(id<HNKCacheEntity>)entity placeholderImage:(UIImage*)placeholderImage
{
    [self hnk_setImageFromEntity:entity placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)hnk_setImageFromEntity:(id<HNKCacheEntity>)entity success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    [self hnk_setImageFromEntity:entity placeholderImage:nil success:successBlock failure:failureBlock];
}

- (void)hnk_setImageFromEntity:(id<HNKCacheEntity>)entity placeholderImage:(UIImage*)placeholderImage success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    [self hnk_cancelImageRequest];
    self.hnk_requestedCacheKey = entity.cacheKey;
    const BOOL didSetImage = [self hnk_retrieveImageFromEntity:entity success:successBlock failure:failureBlock];
    if (!didSetImage && placeholderImage != nil)
    {
        self.image = placeholderImage;
    }
}

- (void)setHnk_cacheFormat:(HNKCacheFormat *)hnk_cacheFormat
{
    HNKCache *cache = [HNKCache sharedCache];
    if (cache.formats[hnk_cacheFormat.name] != hnk_cacheFormat)
    {
        [[HNKCache sharedCache] registerFormat:hnk_cacheFormat];
    }
    objc_setAssociatedObject(self, @selector(hnk_cacheFormat), hnk_cacheFormat, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.contentMode = (UIViewContentMode)hnk_cacheFormat.scaleMode;
}

- (HNKCacheFormat*)hnk_cacheFormat
{
    HNKCacheFormat *format = (HNKCacheFormat *)objc_getAssociatedObject(self, @selector(hnk_cacheFormat));
    if (format) return format;

    CGSize viewSize = self.bounds.size;
    NSAssert(viewSize.width > 0 && viewSize.height > 0, @"%s: UImageView size is zero. Set its frame, call sizeToFit or force layout first.", __PRETTY_FUNCTION__);
    HNKScaleMode scaleMode = self.hnk_scaleMode;
    NSString *scaleModeName = NSStringFromHNKScaleMode(scaleMode);
    NSString *name = [NSString stringWithFormat:@"auto-%ldx%ld-%@", (long)viewSize.width, (long)viewSize.height, scaleModeName];
    HNKCache *cache = [HNKCache sharedCache];
    format = cache.formats[name];
    if (!format)
    {
        format = [[HNKCacheFormat alloc] initWithName:name];
        format.size = viewSize;
        format.diskCapacity = 10 * 1024 * 1024;
        format.allowUpscaling = YES;
        format.compressionQuality = 0.75;
        format.scaleMode = scaleMode;
        [cache registerFormat:format];
    }
    return format;
}

- (void)hnk_cancelImageRequest
{
    if ([self.hnk_entity respondsToSelector:@selector(cancelFetch)])
    {
        [self.hnk_entity cancelFetch];
    }
    self.hnk_entity = nil;
    self.hnk_requestedCacheKey = nil;
}

#pragma mark Private

- (BOOL)hnk_retrieveImageFromEntity:(id<HNKCacheEntity>)entity success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    HNKCacheFormat *format = self.hnk_cacheFormat;
    __block BOOL animated = NO;
    const BOOL didSetImage = [[HNKCache sharedCache] retrieveImageForEntity:entity formatName:format.name completionBlock:^(UIImage *image, NSError *error) {
        if ([self hnk_shouldCancelRequestForKey:entity.cacheKey formatName:format.name]) return;
        
        if (image)
        {
            [self hnk_setImage:image animated:animated success:successBlock];
        }
        else
        {
            [self hnk_failWithError:error failure:failureBlock];
        }
    }];
    animated = YES;
    return didSetImage;
}

- (void)hnk_failWithError:(NSError*)error failure:(void (^)(NSError *error))failureBlock
{
    self.hnk_entity = nil;
    self.hnk_requestedCacheKey = nil;
    
    if (failureBlock) failureBlock(error);
}


- (void)hnk_setImage:(UIImage*)image animated:(BOOL)animated success:(void (^)(UIImage *image))successBlock
{
    self.hnk_entity = nil;
    self.hnk_requestedCacheKey = nil;
    
    if (successBlock)
    {
        successBlock(image);
    }
    else
    {
        const NSTimeInterval duration = animated ? 0.1 : 0;
        [UIView transitionWithView:self duration:duration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            self.image = image;
        } completion:nil];
    }
}

- (HNKScaleMode)hnk_scaleMode
{
    switch (self.contentMode) {
        case UIViewContentModeScaleToFill:
            return HNKScaleModeFill;
        case UIViewContentModeScaleAspectFit:
            return HNKScaleModeAspectFit;
        case UIViewContentModeScaleAspectFill:
            return HNKScaleModeAspectFill;
        case UIViewContentModeRedraw:
        case UIViewContentModeCenter:
        case UIViewContentModeTop:
        case UIViewContentModeBottom:
        case UIViewContentModeLeft:
        case UIViewContentModeRight:
        case UIViewContentModeTopLeft:
        case UIViewContentModeTopRight:
        case UIViewContentModeBottomLeft:
        case UIViewContentModeBottomRight:
            return HNKScaleModeFill;
    }
}

- (BOOL)hnk_shouldCancelRequestForKey:(NSString*)key formatName:(NSString*)formatName
{
    if ([self.hnk_requestedCacheKey isEqualToString:key]) return NO;
    
    HanekeLog(@"Cancelled request due to view reuse: %@/%@", formatName, key.lastPathComponent);
    return YES;
}

#pragma mark Properties (Private)

- (NSString*)hnk_requestedCacheKey
{
    return (NSString *)objc_getAssociatedObject(self, @selector(hnk_requestedCacheKey));
}

- (void)setHnk_requestedCacheKey:(NSString*)cacheKey
{
    objc_setAssociatedObject(self, @selector(hnk_requestedCacheKey), cacheKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<HNKCacheEntity>)hnk_entity
{
    return (id<HNKCacheEntity>)objc_getAssociatedObject(self, @selector(hnk_entity));
}

- (void)setHnk_entity:(id<HNKCacheEntity>)entity
{
    objc_setAssociatedObject(self, @selector(hnk_entity), entity, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
