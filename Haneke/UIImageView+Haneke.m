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
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if ([self hnk_shouldCancelRequestForKey:path formatName:formatName]) return;
            
            NSError *error = nil;
            NSData *originalData = [NSData dataWithContentsOfFile:path options:kNilOptions error:&error];
            if (!originalData)
            {
                HanekeLog(@"Request %@ failed with error %@", path, error);
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self hnk_failWithError:error failure:failureBlock];
                });
                return;
            }

            if ([self hnk_shouldCancelRequestForKey:path formatName:formatName]) return;
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                if ([self hnk_shouldCancelRequestForKey:path formatName:formatName]) return;
                
                HNKImageViewEntity *entity = [HNKImageViewEntity entityWithData:originalData key:path];
                [self hnk_retrieveImageFromEntity:entity success:successBlock failure:failureBlock];
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

        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            if ([self hnk_shouldCancelRequestForKey:absoluteString formatName:formatName]) return;
            
            if (error)
            {
                HanekeLog(@"Request %@ failed with error %@", absoluteString, error);
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [self hnk_failWithError:error failure:failureBlock];
                });
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
                    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorDescription , NSURLErrorKey : url};
                    NSError *error = [NSError errorWithDomain:HNKErrorDomain code:HNKErrorImageFromURLMissingData userInfo:userInfo];
                    dispatch_async(dispatch_get_main_queue(), ^
                    {
                        [self hnk_failWithError:error failure:failureBlock];
                    });
                    return;
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^
            {
                HNKImageViewEntity *entity = [HNKImageViewEntity entityWithData:data key:absoluteString];
                [self hnk_retrieveImageFromEntity:entity success:successBlock failure:failureBlock];
                self.hnk_URLSessionDataTask = nil;
            });
            
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
    HNKImageViewEntity *entity = [HNKImageViewEntity entityWithImage:originalImage key:key];
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
    [self.hnk_URLSessionDataTask cancel];
    self.hnk_URLSessionDataTask = nil;
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
    self.hnk_URLSessionDataTask = nil;
    self.hnk_requestedCacheKey = nil;
    
    if (failureBlock) failureBlock(error);
}


- (void)hnk_setImage:(UIImage*)image animated:(BOOL)animated success:(void (^)(UIImage *image))successBlock
{
    self.hnk_URLSessionDataTask = nil;
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

- (NSURLSessionDataTask*)hnk_URLSessionDataTask
{
    return (NSURLSessionDataTask *)objc_getAssociatedObject(self, @selector(hnk_URLSessionDataTask));
}

- (void)setHnk_URLSessionDataTask:(NSURLSessionDataTask*)URLSessionDataTask
{
    objc_setAssociatedObject(self, @selector(hnk_URLSessionDataTask), URLSessionDataTask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end