//
//  HNKCache.m
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

#import "HNKCache.h"
#import "HNKDiskCache.h"

NSString *const HNKErrorDomain = @"com.hpique.haneke";

#define hnk_dispatch_sync_main_queue_if_needed(block)\
    if ([NSThread isMainThread])\
    {\
        block();\
    }\
    else\
    {\
        dispatch_sync(dispatch_get_main_queue(), block);\
    }

@interface UIImage (Haneke)

- (CGSize)hnk_aspectFillSizeForSize:(CGSize)size;
- (CGSize)hnk_aspectFitSizeForSize:(CGSize)size;
- (NSData*)hnk_dataWithCompressionQuality:(CGFloat)compressionQuality;
- (UIImage *)hnk_decompressedImage;
- (UIImage *)hnk_imageByScalingToSize:(CGSize)newSize;
- (BOOL)hnk_hasAlpha;

@end

@interface HNKCacheFormat()

@property (nonatomic, weak) HNKCache *cache;
@property (nonatomic, readonly) NSString *directory;
@property (nonatomic, assign) NSUInteger requestCount;
@property (nonatomic, strong) HNKDiskCache *diskCache;

@end

@interface HNKCache()

@property (nonatomic, readonly) NSString *rootDirectory;

@end

@implementation HNKCache {
    NSMutableDictionary *_memoryCaches;
    NSMutableDictionary *_formats;
    NSString *_rootDirectory;
}

#pragma mark Initializing the cache

- (instancetype)initWithName:(NSString*)name
{
    self = [super init];
    if (self)
    {
        _memoryCaches = [NSMutableDictionary dictionary];
        _formats = [NSMutableDictionary dictionary];
        
        NSString *cachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        static NSString *cachePathComponent = @"com.hpique.haneke";
        NSString *path = [cachesDirectory stringByAppendingPathComponent:cachePathComponent];
        _rootDirectory = [path stringByAppendingPathComponent:name];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

+ (HNKCache*)sharedCache
{
    static HNKCache *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HNKCache alloc] initWithName:@"shared"];
    });
    return instance;
}

- (void)registerFormat:(HNKCacheFormat *)format
{
    NSString *formatName = format.name;
    if (_formats[formatName])
    {
        [self removeImagesOfFormatNamed:formatName];
    }
    _formats[formatName] = format;
    format.cache = self;
    format.diskCache = [[HNKDiskCache alloc] initWithDirectory:format.directory capacity:format.diskCapacity];
    [self enumeratePreloadImagesOfFormat:format usingBlock:^(NSString *key, UIImage *image) {
        [self setMemoryImage:image forKey:key format:format];
    }];
}

- (NSDictionary*)formats
{
    return _formats.copy;
}

#pragma mark Getting images

- (BOOL)fetchImageForFetcher:(id<HNKFetcher>)fetcher formatName:(NSString *)formatName success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    NSString *key = fetcher.key;
    return [self fetchImageForKey:key formatName:formatName success:^(UIImage *image) {
        if (successBlock) successBlock(image);
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            HNKCacheFormat *format = _formats[formatName];
            
            [self fetchImageFromFetcher:fetcher completionBlock:^(UIImage *originalImage, NSError *error) {
                if (!originalImage)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (failureBlock) failureBlock(error);
                    });
                    return;
                }
                
                UIImage *image = [self imageFromOriginal:originalImage key:key format:format];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setMemoryImage:image forKey:key format:format];
                    if (successBlock) successBlock(image);
                });
                [self setDiskImage:image forKey:key format:format];
            }];
        });
    }];
}

- (BOOL)fetchImageForKey:(NSString*)key formatName:(NSString *)formatName success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock
{
    HNKCacheFormat *format = _formats[formatName];
    NSAssert(format, @"Unknown format %@", formatName);
    format.requestCount++;
    
    UIImage *image = [self memoryImageForKey:key format:format];
    if (image)
    {
        HanekeLog(@"Memory cache hit: %@/%@", formatName, key.lastPathComponent);
        if (successBlock) successBlock(image);
        [self updateAccessDateOfImage:image key:key format:format];
        return YES;
    }
    HanekeLog(@"Memory cache miss: %@/%@", formatName, key.lastPathComponent);
    
    [format.diskCache fetchDataForKey:key success:^(NSData *data) {
        HanekeLog(@"Disk cache hit: %@/%@", formatName, key.lastPathComponent);
        UIImage *image = [UIImage imageWithData:data];
        if (image)
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage *decompressedImage = [image hnk_decompressedImage];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setMemoryImage:decompressedImage forKey:key format:format];
                    if (successBlock) successBlock(decompressedImage);
                });
            });
            [self updateAccessDateOfImage:image key:key format:format];
        }
        else
        {
            NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Disk cache: Cannot read image for key %@", @""), key.lastPathComponent];
            HanekeLog(@"%@", errorDescription);
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorDescription};
            NSError *error = [NSError errorWithDomain:HNKErrorDomain code:HNKErrorDiskCacheCannotReadImageFromData userInfo:userInfo];
            if (failureBlock) failureBlock(error);
        }
    } failure:^(NSError *error) {
        if (error.code == NSFileReadNoSuchFileError)
        {
            HanekeLog(@"Disk cache miss: %@/%@", formatName, key.lastPathComponent);
            NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Image not found for key %@", @""), key.lastPathComponent];
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorDescription };
            NSError *error = [NSError errorWithDomain:HNKErrorDomain code:HNKErrorImageNotFound userInfo:userInfo];
            if (failureBlock) failureBlock(error);
        }
        else
        {
            if (failureBlock) failureBlock(error);
        }
    }];
    return NO;
}

#pragma mark Setting images

- (void)setImage:(UIImage*)image forKey:(NSString*)key formatName:(NSString*)formatName
{
    HNKCacheFormat *format = _formats[formatName];
    NSAssert(format, @"Unknown format %@", formatName);
    
    [self setMemoryImage:image forKey:key format:format];
    [self setDiskImage:image forKey:key format:format];
}

#pragma mark Removing images

- (void)removeImagesOfFormatNamed:(NSString*)formatName
{
    HNKCacheFormat *format = _formats[formatName];
    if (!format) return;
    NSCache *cache = _memoryCaches[formatName];
    [cache removeAllObjects];
    [format.diskCache removeAllData];
}

- (void)removeAllImages
{
    [self.formats enumerateKeysAndObjectsUsingBlock:^(NSString *name, id obj, BOOL *stop)
     {
         [self removeImagesOfFormatNamed:name];
     }];
}

- (void)removeImagesForKey:(NSString *)key
{
    [_memoryCaches enumerateKeysAndObjectsUsingBlock:^(id _, NSCache *cache, BOOL *stop) {
        [cache removeObjectForKey:key];
    }];
    NSDictionary *formats = _formats.copy;
    [formats enumerateKeysAndObjectsUsingBlock:^(id _, HNKCacheFormat *format, BOOL *stop) {
        [self setDiskImage:nil forKey:key format:format];
    }];
}

#pragma mark Private (utils)

- (void)fetchImageFromFetcher:(id<HNKFetcher>)fetcher completionBlock:(void(^)(UIImage *image, NSError *error))completionBlock;
{
    hnk_dispatch_sync_main_queue_if_needed((^{
        [fetcher fetchImageWithSuccess:^(UIImage *image) {
            if (image)
            {
                completionBlock(image, nil);
            }
            else
            {
                NSString *key = fetcher.key;
                NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Invalid fetcher %@: Must return non-nil in success block", @""), key.lastPathComponent];
                HanekeLog(@"%@", errorDescription);
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorDescription };
                NSError *error = [NSError errorWithDomain:HNKErrorDomain code:HNKErrorFetcherMustReturnImage userInfo:userInfo];
                completionBlock(nil, error);
                return;
            }
        } failure:^(NSError *error) {
            completionBlock(nil, error);
        }];
    }));
}

- (UIImage*)imageFromOriginal:(UIImage*)original key:(NSString*)key format:(HNKCacheFormat*)format
{
    UIImage *image = format.preResizeBlock ? format.preResizeBlock(key, original) : original;
    image = [format resizedImageFromImage:image];
    if (format.postResizeBlock) image = format.postResizeBlock(key, image);
    if (image == original)
    {
        image = [image hnk_decompressedImage];
    }
    return image;
}

#pragma mark Private (memory)

- (UIImage*)memoryImageForKey:(NSString*)key format:(HNKCacheFormat*)format
{
    NSCache *cache = _memoryCaches[format.name];
    return [cache objectForKey:key];
}

- (void)setMemoryImage:(UIImage*)image forKey:(NSString*)key format:(HNKCacheFormat*)format
{
    NSString *formatName = format.name;
    NSCache *cache = _memoryCaches[formatName];
    if (!cache)
    {
        cache = [[NSCache alloc] init];
        _memoryCaches[formatName] = cache;
    }
    if (image)
    {
        [cache setObject:image forKey:key];
    }
    else
    {
        [cache removeObjectForKey:key];
    }
}

#pragma mark Private (disk)

- (void)enumeratePreloadImagesOfFormat:(HNKCacheFormat*)format usingBlock:(void(^)(NSString *key, UIImage *image))block
{
    HNKPreloadPolicy preloadPolicy = format.preloadPolicy;
    if (preloadPolicy == HNKPreloadPolicyNone) return;
    __block NSDate *maxDate = preloadPolicy == HNKPreloadPolicyAll ? [NSDate distantPast] : nil;
    [format.diskCache enumerateDataByAccessDateUsingBlock:^(NSString *key, NSData *data, NSDate *accessDate, BOOL *stop) {
        if (format.requestCount > 0)
        {
            *stop = YES;
            return;
        }
        
        if (!maxDate)
        {
            static const NSTimeInterval hourInterval = 3600;
            maxDate = [accessDate dateByAddingTimeInterval:-hourInterval];
        }
        if ([accessDate earlierDate:maxDate] == accessDate)
        {
            *stop = YES;
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image = [UIImage imageWithData:data];
            if (!image) return;
            image = [image hnk_decompressedImage];
            dispatch_async(dispatch_get_main_queue(), ^{
                block(key, image);
            });
        });
    }];
}

- (void)setDiskImage:(UIImage*)image forKey:(NSString*)key format:(HNKCacheFormat*)format
{
    if (image)
    {
        if (format.diskCapacity == 0) return;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *data = [image hnk_dataWithCompressionQuality:format.compressionQuality];
            dispatch_async(dispatch_get_main_queue(), ^{
                [format.diskCache setData:data forKey:key];
            });
        });
    }
    else
    {
        [format.diskCache removeDataForKey:key];
    }
}

- (void)updateAccessDateOfImage:(UIImage*)image key:(NSString*)key format:(HNKCacheFormat*)format
{
    [format.diskCache updateAccessDateForKey:key data:^NSData *{
        NSData *data = [image hnk_dataWithCompressionQuality:format.compressionQuality];
        return data;
    }];
}

#pragma mark Notifications

- (void)didReceiveMemoryWarning:(NSNotification*)notification
{
    [_memoryCaches enumerateKeysAndObjectsUsingBlock:^(id key, NSCache *cache, BOOL *stop) {
        [cache removeAllObjects];
    }];
}

@end

@implementation HNKCacheFormat

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self)
    {
        _name = name;
        _compressionQuality = 1;
    }
    return self;
}

- (UIImage*)resizedImageFromImage:(UIImage*)originalImage
{
    const CGSize formatSize = self.size;
    CGSize resizedSize;
    switch (self.scaleMode) {
        case HNKScaleModeAspectFill:
            resizedSize = [originalImage hnk_aspectFillSizeForSize:formatSize];
            break;
        case HNKScaleModeAspectFit:
            resizedSize = [originalImage hnk_aspectFitSizeForSize:formatSize];
            break;
        case HNKScaleModeFill:
            resizedSize = formatSize;
            break;
        case HNKScaleModeNone:
            return originalImage;
    }
    const CGSize originalSize = originalImage.size;
    if (!self.allowUpscaling)
    {
        if (resizedSize.width > originalSize.width || resizedSize.height > originalSize.height)
        {
            return originalImage;
        }
    }
    if (resizedSize.width == originalSize.width && resizedSize.height == originalSize.height)
    {
        return originalImage;
    }
    UIImage *image = [originalImage hnk_imageByScalingToSize:resizedSize];
    return image;
}

- (unsigned long long)diskSize
{
    return self.diskCache.size;
}

- (void)setDiskCapacity:(unsigned long long)diskCapacity
{
    _diskCapacity = diskCapacity;
    self.diskCache.capacity = _diskCapacity;
}

#pragma mark Private

- (NSString*)directory
{
    NSString *rootDirectory = self.cache.rootDirectory;
    NSString *directory = [rootDirectory stringByAppendingPathComponent:self.name];
    NSError *error;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error])
    {
        NSLog(@"Failed to create directory with error %@", error);
    }
    return directory;
}

@end

@implementation UIImage (hnk_utils)

- (CGSize)hnk_aspectFillSizeForSize:(CGSize)size
{
    const CGFloat scaleWidth = size.width / self.size.width;
    const CGFloat scaleHeight = size.height / self.size.height;
    const CGFloat scale = MAX(scaleWidth, scaleHeight);
    CGSize resultSize;
    resultSize.width = self.size.width * scale;
    resultSize.height = self.size.height * scale;
    return CGSizeMake(ceil(resultSize.width), ceil(resultSize.height));
}

- (NSData*)hnk_dataWithCompressionQuality:(CGFloat)compressionQuality
{
    const BOOL hasAlpha = [self hnk_hasAlpha];
    NSData *data = hasAlpha ? UIImagePNGRepresentation(self) : UIImageJPEGRepresentation(self, compressionQuality);
    return data;
}

- (CGSize)hnk_aspectFitSizeForSize:(CGSize)size
{
    const CGFloat targetAspect = size.width / size.height;
    const CGFloat sourceAspect = self.size.width / self.size.height;
    CGSize resultSize = size;
    if (targetAspect > sourceAspect)
    {
        resultSize.width = size.height * sourceAspect;
    }
    else
    {
        resultSize.height = size.width / sourceAspect;
    }
    return CGSizeMake(ceil(resultSize.width), ceil(resultSize.height));
}

- (UIImage *)hnk_decompressedImage;
{
    // Ideally we would simply use kCGImageSourceShouldCacheImmediately but as of iOS 7.1 it locks on copyImageBlockSetJPEG which makes it dangerous.
    // const CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    // CGImageRef imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, (__bridge CFDictionaryRef)@{(id)kCGImageSourceShouldCacheImmediately: @YES});
    
    CGImageRef originalImageRef = self.CGImage;
    const CGBitmapInfo originalBitmapInfo = CGImageGetBitmapInfo(originalImageRef);
    
    // See: http://stackoverflow.com/questions/23723564/which-cgimagealphainfo-should-we-use
    const uint32_t alphaInfo = (originalBitmapInfo & kCGBitmapAlphaInfoMask);
    CGBitmapInfo bitmapInfo = originalBitmapInfo;
    switch (alphaInfo)
    {
        case kCGImageAlphaNone:
            bitmapInfo &= ~kCGBitmapAlphaInfoMask;
            bitmapInfo |= kCGImageAlphaNoneSkipFirst;
            break;
        case kCGImageAlphaPremultipliedFirst:
        case kCGImageAlphaPremultipliedLast:
        case kCGImageAlphaNoneSkipFirst:
        case kCGImageAlphaNoneSkipLast:
            break;
        case kCGImageAlphaOnly:
        case kCGImageAlphaLast:
        case kCGImageAlphaFirst:
        { // Unsupported
            return self;
        }
            break;
    }
    
    const CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    const CGSize pixelSize = CGSizeMake(self.size.width * self.scale, self.size.height * self.scale);
    const CGContextRef context = CGBitmapContextCreate(NULL,
                                                       pixelSize.width,
                                                       pixelSize.height,
                                                       CGImageGetBitsPerComponent(originalImageRef),
                                                       0,
                                                       colorSpace,
                                                       bitmapInfo);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *image;
    if (!context) return self;
    
    const CGRect imageRect = CGRectMake(0, 0, pixelSize.width, pixelSize.height);
    UIGraphicsPushContext(context);
    
    // Flip coordinate system. See: http://stackoverflow.com/questions/506622/cgcontextdrawimage-draws-image-upside-down-when-passed-uiimage-cgimage
    CGContextTranslateCTM(context, 0, pixelSize.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // UIImage and drawInRect takes into account image orientation, unlike CGContextDrawImage.
    [self drawInRect:imageRect];
    UIGraphicsPopContext();
    const CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    const CGFloat scale = [UIScreen mainScreen].scale;
    image = [UIImage imageWithCGImage:decompressedImageRef scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(decompressedImageRef);
    
    return image;
}

- (BOOL)hnk_hasAlpha
{
    const CGImageAlphaInfo alpha = CGImageGetAlphaInfo(self.CGImage);
    return (alpha == kCGImageAlphaFirst ||
            alpha == kCGImageAlphaLast ||
            alpha == kCGImageAlphaPremultipliedFirst ||
            alpha == kCGImageAlphaPremultipliedLast);
}

- (UIImage *)hnk_imageByScalingToSize:(CGSize)newSize
{
    const BOOL hasAlpha = [self hnk_hasAlpha];
    UIGraphicsBeginImageContextWithOptions(newSize, !hasAlpha, 0.0);
    [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
