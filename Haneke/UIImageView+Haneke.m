//
//  UIImageView+Haneke.m
//  Haneke
//
//  Created by Hermes on 12/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "UIImageView+Haneke.h"
#import <objc/runtime.h>

@interface HNKImageViewEntity : NSObject<HNKCacheEntity>

+ (HNKImageViewEntity*)entityWithImage:(UIImage*)image key:(NSString*)key;

+ (HNKImageViewEntity*)entityWithData:(NSData*)data key:(NSString*)key;

@end

static NSString *NSStringFromHNKScaleMode(HNKScaleMode scaleMode)
{
    switch (scaleMode) {
        case HNKScaleModeFill:
            return @"fill";
        case HNKScaleModeAspectFill:
            return @"aspectfill";
        case HNKScaleModeAspectFit:
            return @"aspectfit";
    }
    return nil;
}

@implementation UIImageView (Haneke)

- (void)hnk_setImageFromFile:(NSString*)path
{
    [self hnk_setImageFromFile:path placeholderImage:nil failure:nil];
}

- (void)hnk_setImageFromFile:(NSString*)path placeholderImage:(UIImage *)placeholderImage
{
    [self hnk_setImageFromFile:path placeholderImage:placeholderImage failure:nil];
}

- (void)hnk_setImageFromFile:(NSString*)path failure:(void (^)(NSError *))failureBlock
{
    [self hnk_setImageFromFile:path placeholderImage:nil failure:failureBlock];
}

- (void)hnk_setImageFromFile:(NSString*)path placeholderImage:(UIImage*)placeholderImage failure:(void (^)(NSError *error))failureBlock
{
    [self hnk_cancelImageRequest];
    self.hnk_lastCacheKey = path;
    HNKCacheFormat *format = self.hnk_cacheFormat;
    __block BOOL animated = NO;
    const BOOL didSetImage = [[HNKCache sharedCache] retrieveImageForKey:path formatName:format.name completionBlock:^(NSString *key, NSString *formatName, UIImage *image, NSError *error) {
        if ([self hnk_shouldCancelRequestForKey:key formatName:formatName]) return;
        
        if (image)
        {
            [self hnk_setImage:image animated:animated];
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if ([self hnk_shouldCancelRequestForKey:key formatName:formatName]) return;
            
            NSError *error = nil;
            NSData *originalData = [NSData dataWithContentsOfFile:path options:kNilOptions error:&error];
            if (!originalData)
            {
                HanekeLog(@"Request %@ failed with error %@", path, error);
                if (failureBlock)
                {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        failureBlock(error);
                    });
                }
                return;
            }

            if ([self hnk_shouldCancelRequestForKey:key formatName:formatName]) return;
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                if ([self hnk_shouldCancelRequestForKey:key formatName:formatName]) return;
                
                HNKImageViewEntity *entity = [HNKImageViewEntity entityWithData:originalData key:path];
                [self hnk_retrieveImageFromEntity:entity failure:failureBlock];
            });
        });
    }];
    animated = YES;
    if (!didSetImage && placeholderImage != nil)
    {
        self.image = placeholderImage;
    }
}

- (void)hnk_setImageFromURL:(NSURL*)url
{
    [self hnk_setImageFromURL:url placeholderImage:nil failure:nil];
}

- (void)hnk_setImageFromURL:(NSURL*)url placeholderImage:(UIImage *)placeholderImage
{
    [self hnk_setImageFromURL:url placeholderImage:placeholderImage failure:nil];
}

- (void)hnk_setImageFromURL:(NSURL*)url failure:(void (^)(NSError *error))failureBlock
{
    [self hnk_setImageFromURL:url placeholderImage:nil failure:failureBlock];
}

- (void)hnk_setImageFromURL:(NSURL*)url placeholderImage:(UIImage*)placeholderImage failure:(void (^)(NSError *error))failureBlock
{
    [self hnk_cancelImageRequest];
    NSString *absoluteString = url.absoluteString;
    self.hnk_lastCacheKey = absoluteString;
    HNKCacheFormat *format = self.hnk_cacheFormat;
    __block BOOL animated = NO;
    const BOOL didSetImage = [[HNKCache sharedCache] retrieveImageForKey:absoluteString formatName:format.name completionBlock:^(NSString *key, NSString *formatName, UIImage *image, NSError *error) {
        if ([self hnk_shouldCancelRequestForKey:key formatName:formatName]) return;
        
        if (image)
        {
            [self hnk_setImage:image animated:animated];
            return;
        }

        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            if ([self hnk_shouldCancelRequestForKey:key formatName:formatName]) return;
            
            if (error)
            {
                HanekeLog(@"Request %@ failed with error %@", absoluteString, error);
                if (failureBlock) failureBlock(error);
                return;
            }
            const long long expectedContentLength = response.expectedContentLength;
            if (expectedContentLength > -1)
            {
                const NSUInteger dataLength = data.length;
                if (dataLength < expectedContentLength)
                {
                    NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Request %@ received %ld out of %ld bytes", @""), absoluteString, (long)dataLength, (long)expectedContentLength];
                    HanekeLog(@"%@", errorDescription);
                    if (failureBlock)
                    {
                        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorDescription , NSURLErrorKey : url};
                        NSError *error = [NSError errorWithDomain:HNKErrorDomain code:HNKErrorImageFromURLMissingData userInfo:userInfo];
                        failureBlock(error);
                    }
                    return;
                }
            }
            
            HNKImageViewEntity *entity = [HNKImageViewEntity entityWithData:data key:absoluteString];
            [self hnk_retrieveImageFromEntity:entity failure:failureBlock];
            self.hnk_URLSessionDataTask = nil;
        }];
        self.hnk_URLSessionDataTask = task;
        [task resume];
    }];
    animated = YES;
    if (!didSetImage && placeholderImage != nil)
    {
        self.image = placeholderImage;
    }
}

- (void)hnk_setImage:(UIImage*)originalImage withKey:(NSString*)key
{
    HNKImageViewEntity *entity = [HNKImageViewEntity entityWithImage:originalImage key:key];
    [self hnk_setImageFromEntity:entity];
}

- (void)hnk_setImageFromEntity:(id<HNKCacheEntity>)entity
{
    [self hnk_cancelImageRequest];
    self.hnk_lastCacheKey = entity.cacheKey;
    [self hnk_retrieveImageFromEntity:entity failure:nil];
}

- (void)setHnk_cacheFormat:(HNKCacheFormat *)hnk_cacheFormat
{
    HNKCache *cache = [HNKCache sharedCache];
    if (cache.formats[hnk_cacheFormat.name] != hnk_cacheFormat)
    {
        [[HNKCache sharedCache] registerFormat:hnk_cacheFormat];
    }
    objc_setAssociatedObject(self, @selector(hnk_cacheFormat), hnk_cacheFormat, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.contentMode = hnk_cacheFormat.scaleMode;
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
    [self.hnk_URLSessionDataTask cancel];
    self.hnk_URLSessionDataTask = nil;
    self.hnk_lastCacheKey = nil;
}

#pragma mark Private

- (void)hnk_retrieveImageFromEntity:(id<HNKCacheEntity>)entity failure:(void (^)(NSError *error))failureBlock
{
    HNKCacheFormat *format = self.hnk_cacheFormat;
    __block BOOL animated = NO;
    [[HNKCache sharedCache] retrieveImageForEntity:entity formatName:format.name completionBlock:^(id<HNKCacheEntity> entity, NSString *formatName, UIImage *image, NSError *error) {
        if ([self hnk_shouldCancelRequestForKey:entity.cacheKey formatName:formatName]) return;
        
        if (image)
        {
            [self hnk_setImage:image animated:animated];
        }
        else
        {
            if (failureBlock) failureBlock(error);
        }
    }];
    animated = YES;
}

- (void)hnk_setImage:(UIImage*)image animated:(BOOL)animated
{
    const NSTimeInterval duration = animated ? 0.1 : 0;
    [UIView transitionWithView:self duration:duration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.image = image;
    } completion:nil];
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
    if ([self.hnk_lastCacheKey isEqualToString:key]) return NO;
    
    HanekeLog(@"Cancelled request due to view reuse: %@/%@", formatName, key.lastPathComponent);
    return YES;
}

#pragma mark Properties (Private)

- (NSString*)hnk_lastCacheKey
{
    return (NSString *)objc_getAssociatedObject(self, @selector(hnk_lastCacheKey));
}

- (void)setHnk_lastCacheKey:(NSString*)cacheKey
{
    objc_setAssociatedObject(self, @selector(hnk_lastCacheKey), cacheKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSURLSessionDataTask*)hnk_URLSessionDataTask
{
    return (NSURLSessionDataTask *)objc_getAssociatedObject(self, @selector(hnk_URLSessionDataTask));
}

- (void)setHnk_URLSessionDataTask:(NSURLSessionDataTask*)URLSessionDataTask
{
    objc_setAssociatedObject(self, @selector(hnk_URLSessionDataTask), URLSessionDataTask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation HNKImageViewEntity {
    NSString *_key;
    UIImage *_image;
    NSData *_data;
}

+ (HNKImageViewEntity*)entityWithImage:(UIImage*)image key:(NSString*)key
{
    HNKImageViewEntity *entity = [[HNKImageViewEntity alloc] init];
    entity->_key = key.copy;
    entity->_image = image;
    return entity;
}

+ (HNKImageViewEntity*)entityWithData:(NSData*)data key:(NSString*)key
{
    HNKImageViewEntity *entity = [[HNKImageViewEntity alloc] init];
    entity->_key = key.copy;
    entity->_data = data;
    return entity;
}

- (NSString*)cacheKey
{
    return _key;
}

- (UIImage*)cacheOriginalImage
{
    return _image;
}

- (NSData*)cacheOriginalData
{
    return _data;
}

@end
