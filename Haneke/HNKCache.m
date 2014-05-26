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
@import ImageIO;

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

@interface HNKCache(Disk)

- (void)calculateDiskSizeOfFormat:(HNKCacheFormat*)format;

- (void)controlDiskCapacityOfFormat:(HNKCacheFormat*)format;

- (void)enumeratePreloadImagesOfFormat:(HNKCacheFormat*)format usingBlock:(void(^)(NSString *key, UIImage *image))block;

- (NSString*)keyFromPath:(NSString*)path;

- (NSString*)pathForKey:(NSString*)key format:(HNKCacheFormat*)format;

- (void)setDiskImage:(UIImage*)image forKey:(NSString*)key format:(HNKCacheFormat*)format;

- (void)updateAccessDateOfImage:(UIImage*)image key:(NSString*)key format:(HNKCacheFormat*)format;

@end

@interface UIImage (hnk_utils)

- (CGSize)hnk_aspectFillSizeForSize:(CGSize)size;
- (CGSize)hnk_aspectFitSizeForSize:(CGSize)size;
- (UIImage *)hnk_imageByScalingToSize:(CGSize)newSize;
- (BOOL)hnk_hasAlpha;
+ (UIImage *)hnk_decompressedImageWithData:(NSData*)data;

@end

@interface NSFileManager (hnk_utils)

- (void)hnk_enumerateContentsOfDirectoryAtPath:(NSString*)path orderedByProperty:(NSString*)property ascending:(BOOL)ascending usingBlock:(void(^)(NSURL *url, NSUInteger idx, BOOL *stop))block;

@end

@interface HNKCacheFormat()

@property (nonatomic, assign) unsigned long long diskSize;
@property (nonatomic, weak) HNKCache *cache;
@property (nonatomic, readonly) NSString *directory;
@property (nonatomic, strong) dispatch_queue_t diskQueue;
@property (nonatomic, assign) NSUInteger requestCount;

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

- (id)initWithName:(NSString*)name
{
    self = [super init];
    if (self)
    {
        _memoryCaches = [NSMutableDictionary dictionary];
        _formats = [NSMutableDictionary dictionary];
        
        NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
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
    NSString *queueName = [NSString stringWithFormat:@"com.hpique.haneke.disk.%@", formatName];
    format.diskQueue = dispatch_queue_create(queueName.UTF8String, NULL);
    dispatch_async(format.diskQueue, ^{
        [self calculateDiskSizeOfFormat:format];
        [self controlDiskCapacityOfFormat:format];
        [self enumeratePreloadImagesOfFormat:format usingBlock:^(NSString *key, UIImage *image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setMemoryImage:image forKey:key format:format];
            });
        }];
    });
}

- (NSDictionary*)formats
{
    return _formats.copy;
}

#pragma mark Getting images

- (UIImage*)imageForEntity:(id<HNKCacheEntity>)entity formatName:(NSString *)formatName error:(NSError *__autoreleasing *)errorPtr
{
    HNKCacheFormat *format = _formats[formatName];
    NSAssert(format, @"Unknown format %@", formatName);
    format.requestCount++;
    
    NSString *key = entity.cacheKey;
    UIImage *image = [self memoryImageForKey:key format:format];
    if (image)
    {
        HanekeLog(@"Memory cache hit: %@/%@", formatName, key.lastPathComponent);
        dispatch_async(format.diskQueue, ^{
            [self updateAccessDateOfImage:image key:key format:format];
        });
        return image;
    }
    HanekeLog(@"Memory cache miss: %@/%@", formatName, key.lastPathComponent);
    
    NSString *path = [self pathForKey:key format:format];
    __block NSData *imageData;
    dispatch_sync(format.diskQueue, ^{
        imageData = [NSData dataWithContentsOfFile:path];
    });
    if (imageData)
    {
        image = [UIImage hnk_decompressedImageWithData:imageData];
        if (image)
        {
            HanekeLog(@"Disk cache hit: %@/%@", formatName, key.lastPathComponent);
            dispatch_async(format.diskQueue, ^{
                [self updateAccessDateOfImage:image key:key format:format];
            });
            [self setMemoryImage:image forKey:key format:format];
            return image;
        }
    }
    HanekeLog(@"Disk cache miss: %@/%@", formatName, key.lastPathComponent);
    
    UIImage *originalImage = [self imageFromEntity:entity error:errorPtr];
    if (!originalImage) return nil;
    
    image = [self imageFromOriginal:originalImage key:key format:format];
    [self setMemoryImage:image forKey:key format:format];
    dispatch_async(format.diskQueue, ^{
        [self setDiskImage:image forKey:key format:format];
    });
    return image;
}

- (BOOL)retrieveImageForEntity:(id<HNKCacheEntity>)entity formatName:(NSString *)formatName completionBlock:(void(^)(UIImage *image, NSError *error))completionBlock
{
    NSString *key = entity.cacheKey;
    return [self retrieveImageForKey:key formatName:formatName completionBlock:^(UIImage *image, NSError *error) {
        if (image)
        {
            completionBlock(image, error);
            return;
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            HNKCacheFormat *format = _formats[formatName];

            NSError *error = nil;
            UIImage *originalImage = [self imageFromEntity:entity error:&error];
            if (!originalImage)
            {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    completionBlock(nil, error);
                });
                return;
            }
            UIImage *image = [self imageFromOriginal:originalImage key:key format:format];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setMemoryImage:image forKey:key format:format];
                completionBlock(image, error);
            });
            dispatch_async(format.diskQueue, ^{
                [self setDiskImage:image forKey:key format:format];
            });
        });
    }];
}

- (BOOL)retrieveImageForKey:(NSString*)key formatName:(NSString *)formatName completionBlock:(void(^)(UIImage *image, NSError *error))completionBlock
{
    HNKCacheFormat *format = _formats[formatName];
    NSAssert(format, @"Unknown format %@", formatName);
    format.requestCount++;
    
    UIImage *image = [self memoryImageForKey:key format:format];
    if (image)
    {
        HanekeLog(@"Memory cache hit: %@/%@", formatName, key.lastPathComponent);
        completionBlock(image, nil);
        dispatch_async(format.diskQueue, ^{
            [self updateAccessDateOfImage:image key:key format:format];
        });
        return YES;
    }
    HanekeLog(@"Memory cache miss: %@/%@", formatName, key.lastPathComponent);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *path = [self pathForKey:key format:format];
        __block NSData *imageData;
        __block NSError *error = nil;
        dispatch_sync(format.diskQueue, ^{
            imageData = [NSData dataWithContentsOfFile:path options:kNilOptions error:&error];
        });
        if (imageData)
        {
            HanekeLog(@"Disk cache hit: %@/%@", formatName, key.lastPathComponent);
            UIImage *image = [UIImage hnk_decompressedImageWithData:imageData];
            if (image)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setMemoryImage:image forKey:key format:format];
                    completionBlock(image, nil);
                });
                dispatch_async(format.diskQueue, ^{
                    [self updateAccessDateOfImage:image key:key format:format];
                });
            }
            else
            {
                NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Disk cache: Cannot read image from data at path %@", @""), path];
                HanekeLog(@"%@", errorDescription);
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorDescription , NSFilePathErrorKey : path};
                NSError *error = [NSError errorWithDomain:HNKErrorDomain code:HNKErrorDiskCacheCannotReadImageFromData userInfo:userInfo];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, error);
                });
            }
        }
        else
        {
            if (error.code == NSFileReadNoSuchFileError)
            {
                HanekeLog(@"Disk cache miss: %@/%@", formatName, key.lastPathComponent);
                NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Disk cache: Miss at path %@", @""), path];
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorDescription , NSFilePathErrorKey : path};
                NSError *error = [NSError errorWithDomain:HNKErrorDomain code:HNKErrorDiskCacheMiss userInfo:userInfo];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, error);
                });
            }
            else
            {
                NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Disk cache: Cannot read from file at path %@", @""), path];
                HanekeLog(@"%@", errorDescription);
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorDescription , NSFilePathErrorKey : path, NSUnderlyingErrorKey : error};
                NSError *error = [NSError errorWithDomain:HNKErrorDomain code:HNKErrorDiskCacheCannotReadFromFile userInfo:userInfo];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, error);
                });
            }
        }
    });
    return NO;
}

#pragma mark Setting images

- (void)setImage:(UIImage*)image forKey:(NSString*)key formatName:(NSString*)formatName
{
    HNKCacheFormat *format = _formats[formatName];
    NSAssert(format, @"Unknown format %@", formatName);
    
    [self setMemoryImage:image forKey:key format:format];
    dispatch_async(format.diskQueue, ^{
        [self setDiskImage:image forKey:key format:format];
    });
}

#pragma mark Removing images

- (void)removeImagesOfFormatNamed:(NSString*)formatName
{
    HNKCacheFormat *format = _formats[formatName];
    if (!format) return;
    NSCache *cache = [_memoryCaches objectForKey:formatName];
    [cache removeAllObjects];
    NSString *directory = format.directory;
    dispatch_async(format.diskQueue, ^{
        NSError *error;
        if ([[NSFileManager defaultManager] removeItemAtPath:directory error:&error])
        {
            format.diskSize = 0;
        }
        else
        {
            BOOL isDirectory = NO;
            if (![[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDirectory])
            {
                format.diskSize = 0;
            }
            else
            {
                NSLog(@"Failed to remove directory with error %@", error);
            }
        }
    });
}

- (void)removeAllImages
{
    [self.formats enumerateKeysAndObjectsUsingBlock:^(NSString *name, id obj, BOOL *stop)
     {
         [self removeImagesOfFormatNamed:name];
     }];
}

- (void)removeImagesOfEntity:(id<HNKCacheEntity>)entity
{
    NSString *cacheKey = entity.cacheKey;
    [_memoryCaches enumerateKeysAndObjectsUsingBlock:^(id key, NSCache *cache, BOOL *stop) {
        [cache removeObjectForKey:cacheKey];
    }];
    NSDictionary *formats = _formats.copy;
    [formats enumerateKeysAndObjectsUsingBlock:^(id key, HNKCacheFormat *format, BOOL *stop) {
        dispatch_async(format.diskQueue, ^{
            [self setDiskImage:nil forKey:key format:format];
        });
    }];
}

#pragma mark Private (utils)

- (UIImage*)imageFromEntity:(id<HNKCacheEntity>)entity error:(NSError*__autoreleasing *)errorPtr
{
    __block UIImage *image = nil;
    hnk_dispatch_sync_main_queue_if_needed(^{
        image = [entity respondsToSelector:@selector(cacheOriginalImage)] ? entity.cacheOriginalImage : nil;
    });
    if (!image)
    {
        __block NSData *data = nil;
        hnk_dispatch_sync_main_queue_if_needed(^{
            data = [entity respondsToSelector:@selector(cacheOriginalData)] ? entity.cacheOriginalData : nil;
        });
        if (!data)
        {
            NSString *key = entity.cacheKey;
            NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Invalid entity %@: Must return non-nil object in either cacheOriginalImage or cacheOriginalData", @""), key.lastPathComponent];
            HanekeLog(@"%@", errorDescription);
            if (errorPtr != NULL)
            {
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorDescription };
                *errorPtr = [NSError errorWithDomain:HNKErrorDomain code:HNKErrorEntityMustReturnImageOrData userInfo:userInfo];
            }
            return nil;
        }
        image = [UIImage hnk_decompressedImageWithData:data];
        if (!image)
        {
            NSString *key = entity.cacheKey;
            NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Invalid entity %@: Cannot read image from data", @""), key.lastPathComponent];
            HanekeLog(@"%@", errorDescription);
            if (errorPtr != NULL)
            {
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorDescription };
                *errorPtr = [NSError errorWithDomain:HNKErrorDomain code:HNKErrorEntityCannotReadImageFromData userInfo:userInfo];
            }
            return nil;
        }
    }
    return image;
}

- (UIImage*)imageFromOriginal:(UIImage*)original key:(NSString*)key format:(HNKCacheFormat*)format
{
    UIImage *image = format.preResizeBlock ? format.preResizeBlock(key, original) : original;
    image = [format resizedImageFromImage:image];
    if (format.postResizeBlock) image = format.postResizeBlock(key, image);
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
        [cache removeObjectForKey:image];
    }
}

#pragma mark Notifications

- (void)didReceiveMemoryWarning:(NSNotification*)notification
{
    [_memoryCaches enumerateKeysAndObjectsUsingBlock:^(id key, NSCache *cache, BOOL *stop) {
        [cache removeAllObjects];
    }];
}

@end

@implementation HNKCache(Disk)

- (void)calculateDiskSizeOfFormat:(HNKCacheFormat*)format
{
    NSString *directory = format.directory;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    format.diskSize = 0;
    NSError *error;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:directory error:&error];
    if (!contents)
    {
        NSLog(@"Failed to list directory with error %@", error);
        return;
    }
    for (NSString *pathComponent in contents)
    {
        NSString *path = [directory stringByAppendingPathComponent:pathComponent];
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:&error];
        if (!attributes) continue;
        
        format.diskSize += attributes.fileSize;
    }
}

- (void)controlDiskCapacityOfFormat:(HNKCacheFormat*)format
{
    if (format.diskSize <= format.diskCapacity) return;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager hnk_enumerateContentsOfDirectoryAtPath:format.directory orderedByProperty:NSURLContentModificationDateKey ascending:YES usingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
        NSString *path = url.path;
        [self removeFileAtPath:path format:format];
        if (format.diskSize <= format.diskCapacity)
        {
            *stop = YES;
        }
    }];
}

- (void)enumeratePreloadImagesOfFormat:(HNKCacheFormat*)format usingBlock:(void(^)(NSString *key, UIImage *image))block
{
    HNKPreloadPolicy preloadPolicy = format.preloadPolicy;
    if (preloadPolicy == HNKPreloadPolicyNone) return;
    
    NSString *directory = format.directory;
    __block NSDate *maxDate = preloadPolicy == HNKPreloadPolicyAll ? [NSDate distantPast] : nil;
    [[NSFileManager defaultManager] hnk_enumerateContentsOfDirectoryAtPath:directory orderedByProperty:NSURLContentModificationDateKey ascending:NO usingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
        if (format.requestCount > 0)
        {
            *stop = YES;
            return;
        }
        NSDate *urlDate;
        [url getResourceValue:&urlDate forKey:NSURLContentModificationDateKey error:nil];
        if (!maxDate)
        {
            static const NSTimeInterval hourInterval = 3600;
            maxDate = [urlDate dateByAddingTimeInterval:-hourInterval];
        }
        if ([urlDate earlierDate:maxDate] == urlDate)
        {
            *stop = YES;
            return;
        }
        NSString *path = url.path;
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (!data) return;
        UIImage *image = [UIImage hnk_decompressedImageWithData:data];
        if (!image) return;
        NSString *key = [self keyFromPath:path];
        block(key, image);
    }];
}

- (NSString*)keyFromPath:(NSString*)path
{
    NSString *escapedKey = path.lastPathComponent;
    NSString *key = CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (CFStringRef)escapedKey, CFSTR(""), kCFStringEncodingUTF8));
    return key;
}

- (NSString*)pathForKey:(NSString*)key format:(HNKCacheFormat*)format
{
    NSString *escapedKey = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)key, NULL, CFSTR("/:"), kCFStringEncodingUTF8));
    NSString *path = [format.directory stringByAppendingPathComponent:escapedKey];
    return path;
}

- (void)setDiskImage:(UIImage*)image forKey:(NSString*)key format:(HNKCacheFormat*)format
{
    if (image)
    {
        if (format.diskCapacity == 0) return;
        
        const BOOL hasAlpha = [image hnk_hasAlpha];
        NSData *imageData = hasAlpha ? UIImagePNGRepresentation(image) : UIImageJPEGRepresentation(image, format.compressionQuality);

        NSError *error;
        NSString *path = [self pathForKey:key format:format];
        if (![imageData writeToFile:path options:kNilOptions error:&error])
        {
            NSLog(@"Failed to write to file %@", error);
        }
        NSUInteger byteCount = imageData.length;
        format.diskSize += byteCount;
        [self controlDiskCapacityOfFormat:format];
    }
    else
    {
        NSString *path = [self pathForKey:key format:format];
        [self removeFileAtPath:path format:format];
    }
}

- (void)updateAccessDateOfImage:(UIImage*)image key:(NSString*)key format:(HNKCacheFormat*)format
{
    NSString *path = [self pathForKey:key format:format];
    NSDate *now = [NSDate date];
    NSDictionary* attributes = @{NSFileModificationDate : now};
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:path error:&error])
    {
        if ([fileManager fileExistsAtPath:path isDirectory:nil])
        {
            NSLog(@"Set attributes failed with error %@", [error localizedDescription]);
        }
        else
        { // The image was removed from disk cache but is still in the memory cache
            [self setDiskImage:image forKey:key format:format];
        }
    }
}

#pragma mark Utils

- (void)removeFileAtPath:(NSString*)path format:(HNKCacheFormat*)format
{
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:&error];
    if (attributes)
    {
        unsigned long long fileSize = attributes.fileSize;
        if ([fileManager removeItemAtPath:path error:&error])
        {
            format.diskSize -= fileSize;
        }
        else
        {
            NSLog(@"Failed to remove file with error %@", error);
        }
    }
}

@end

@implementation HNKCacheFormat

- (id)initWithName:(NSString *)name
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

+ (UIImage*)hnk_decompressedImageWithData:(NSData*)data
{
    const CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);

    // Ideally we would simply use kCGImageSourceShouldCacheImmediately but as of iOS 7.1 it locks on copyImageBlockSetJPEG which makes it dangerous.
    // CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, 0, (__bridge CFDictionaryRef)@{(id)kCGImageSourceShouldCacheImmediately: @YES});

    UIImage *image = nil;
    const CGImageRef imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
    if (imageRef)
    {
        image = [self hnk_decompressedImageWithCGImage:imageRef];
        CGImageRelease(imageRef);
    }
    CFRelease(sourceRef);

    return image;
}

+ (UIImage*)hnk_decompressedImageWithCGImage:(CGImageRef)imageRef
{
    const CGBitmapInfo originalBitmapInfo = CGImageGetBitmapInfo(imageRef);

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
            return [UIImage imageWithCGImage:imageRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        }
            break;
    }

    const CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    const CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    const CGContextRef context = CGBitmapContextCreate(NULL,
                                                       imageSize.width,
                                                       imageSize.height,
                                                       CGImageGetBitsPerComponent(imageRef),
                                                       0,
                                                       colorSpace,
                                                       bitmapInfo);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *image;
    const CGFloat scale = [UIScreen mainScreen].scale;
    if (context)
    {
        const CGRect imageRect = CGRectMake(0, 0, imageSize.width, imageSize.height);
        CGContextDrawImage(context, imageRect, imageRef);
        const CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
        image = [UIImage imageWithCGImage:decompressedImageRef scale:scale orientation:UIImageOrientationUp];
        CGImageRelease(decompressedImageRef);
    }
    else
    {
        image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
    }
    return image;
}
        
@end

@implementation NSFileManager(hnk_utils)

- (void)hnk_enumerateContentsOfDirectoryAtPath:(NSString*)path orderedByProperty:(NSString*)property ascending:(BOOL)ascending usingBlock:(void(^)(NSURL *url, NSUInteger idx, BOOL *stop))block
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *directoryURL = [NSURL fileURLWithPath:path];
    NSError *error;
    NSArray *contents = [fileManager contentsOfDirectoryAtURL:directoryURL includingPropertiesForKeys:@[property] options:kNilOptions error:&error];
    if (!contents)
    {
        NSLog(@"Failed to list directory with error %@", error);
        return;
    }
    contents = [contents sortedArrayUsingComparator:^NSComparisonResult(NSURL *url1, NSURL *url2) {
        id value1;
        [url1 getResourceValue:&value1 forKey:property error:nil];
        id value2;
        [url2 getResourceValue:&value2 forKey:property error:nil] ;
        return ascending ? [value1 compare:value2] : [value2 compare:value1];
    }];
    [contents enumerateObjectsUsingBlock:block];
}

@end
