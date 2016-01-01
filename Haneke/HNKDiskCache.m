//
//  HNKDiskCache.m
//  Haneke
//
//  Created by Hermes Pique on 8/21/14.
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

#import "HNKDiskCache.h"
#import <CommonCrypto/CommonDigest.h> // For hnk_MD5String
#import <sys/xattr.h> // For hnk_setValue:forExtendedFileAttribute:

NSString *const HNKExtendedFileAttributeKey = @"io.haneke.key";

@interface NSString (hnk_utils)

- (NSString*)hnk_MD5String;
- (BOOL)hnk_setValue:(NSString*)value forExtendedFileAttribute:(NSString*)attribute;
- (NSString*)hnk_stringByEscapingFilename;
- (NSString*)hnk_valueForExtendedFileAttribute:(NSString*)attribute;

@end

@interface NSFileManager(Haneke)

- (void)hnk_enumerateContentsOfDirectoryAtPath:(NSString*)path orderedByProperty:(NSString*)property ascending:(BOOL)ascending usingBlock:(void(^)(NSURL *url, NSUInteger idx, BOOL *stop))block;

@end

@implementation HNKDiskCache {
    NSString *_directory;
}

#pragma mark Initializing the cache

- (instancetype)initWithDirectory:(NSString*)directory capacity:(unsigned long long)capacity
{
    if (self = [super init])
    {
        _directory = [directory copy];
        _capacity = capacity;
        NSString *queueName = [NSString stringWithFormat:@"io.haneke.disk.%@", directory.lastPathComponent];
        _queue = dispatch_queue_create(queueName.UTF8String, NULL);
        dispatch_async(_queue, ^{
            [self calculateSize];
            [self controlCapacity];
        });
    }
    return self;
}

- (void)setCapacity:(unsigned long long)capacity
{
    _capacity = capacity;
    dispatch_async(_queue, ^{
        [self controlCapacity];
    });
}

#pragma mark Setting and fetching data

- (void)setData:(NSData*)data forKey:(NSString*)key
{
    dispatch_async(_queue, ^{
        [self syncSetData:data forKey:key];
    });
}

- (void)fetchDataForKey:(NSString*)key success:(void (^)(NSData *data))successBlock failure:(void (^)(NSError *error))failureBlock
{
    dispatch_async(_queue, ^{
        NSString *path = [self pathForKey:key];
        NSError *error = nil;
        NSData *data = [NSData dataWithContentsOfFile:path options:kNilOptions error:&error];
        if (!data)
        {
            if (failureBlock)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failureBlock(error);
                });
            }
            return;
        }
        
        if (successBlock)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(data);
            });
        }
        
        [self syncUpdateAccessDateForKey:key data:^NSData *{ return data; }];
    });
}

#pragma mark Removing data

- (void)removeDataForKey:(NSString*)key
{
    dispatch_async(_queue, ^{
        NSString *path = [self pathForKey:key];
        [self removeFileAtPath:path];
    });
}

- (void)removeAllData
{
    dispatch_async(_queue, ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        NSArray *contents = [fileManager contentsOfDirectoryAtPath:_directory error:&error];
        if (!contents) {
            NSLog(@"Failed to list directory with error %@", error);
            return;
        }
        for (NSString *pathComponent in contents)
        {
            NSString *path = [_directory stringByAppendingPathComponent:pathComponent];
            if (![fileManager removeItemAtPath:path error:&error])
            {
                NSLog(@"Failed to remove file with error %@", error);
            }
        }
        [self calculateSize];
    });
}

#pragma mark Managing data by access date

- (void)enumerateDataByAccessDateUsingBlock:(void(^)(NSString *key, NSData *data, NSDate *accessDate, BOOL *stop))block
{
    dispatch_async(_queue, ^{
        [[NSFileManager defaultManager] hnk_enumerateContentsOfDirectoryAtPath:_directory orderedByProperty:NSURLContentModificationDateKey ascending:NO usingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
            NSDate *accessDate;
            [url getResourceValue:&accessDate forKey:NSURLContentModificationDateKey error:nil];
            
            NSString *path = url.path;
            NSString *key = [path hnk_valueForExtendedFileAttribute:HNKExtendedFileAttributeKey];
            if (!key) return;
            
            NSData *data = [NSData dataWithContentsOfFile:path];
            if (!data) return;
            
            __block BOOL innerStop = NO;
            
            if (block)
            {
                block(key, data, accessDate, &innerStop);
            }
            
            if (innerStop) *stop = YES;
        }];
    });
}

- (void)updateAccessDateForKey:(NSString*)key data:(NSData* (^)())lazyData
{
    dispatch_async(_queue, ^{
        [self syncUpdateAccessDateForKey:key data:lazyData];
    });
}

#pragma mark Private (in _queue)

- (void)calculateSize
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    _size = 0;
    NSError *error;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:_directory error:&error];
    if (!contents)
    {
        NSLog(@"Failed to list directory with error %@", error);
        return;
    }
    for (NSString *pathComponent in contents)
    {
        NSString *path = [_directory stringByAppendingPathComponent:pathComponent];
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:&error];
        if (!attributes) continue;
        
        _size += attributes.fileSize;
    }
}

- (void)controlCapacity
{
    if (self.size <= self.capacity) return;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager hnk_enumerateContentsOfDirectoryAtPath:_directory orderedByProperty:NSURLContentModificationDateKey ascending:YES usingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
        NSString *path = url.path;
        [self removeFileAtPath:path];
        if (self.size <= self.capacity)
        {
            *stop = YES;
        }
    }];
}

- (NSString*)pathForKey:(NSString*)key
{
    NSString *filename = [key hnk_stringByEscapingFilename];
    if (filename.length >= NAME_MAX)
    {
        NSString *MD5 = [key hnk_MD5String];
        NSString *pathExtension = key.pathExtension;
        filename = pathExtension.length > 0 ? [MD5 stringByAppendingPathExtension:pathExtension] : MD5;
    }
    NSString *path = [_directory stringByAppendingPathComponent:filename];
    return path;
}

- (void)removeFileAtPath:(NSString*)path
{
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:&error];
    if (attributes)
    {
        unsigned long long fileSize = attributes.fileSize;
        if ([fileManager removeItemAtPath:path error:&error])
        {
            _size -= fileSize;
        }
        else
        {
            NSLog(@"Failed to remove file with error %@", error);
        }
    }
}

- (void)syncSetData:(NSData*)data forKey:(NSString*)key
{
    NSError *error;
    NSString *path = [self pathForKey:key];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *previousAttributes = [fileManager attributesOfItemAtPath:path error:nil];
    if ([data writeToFile:path options:kNilOptions error:&error])
    {
        [path hnk_setValue:key forExtendedFileAttribute:HNKExtendedFileAttributeKey];
        const NSUInteger byteCount = data.length;
        if (previousAttributes)
        {
            _size -= previousAttributes.fileSize;
        }
        _size += byteCount;
        [self controlCapacity];
    }
    else
    {
        NSLog(@"Failed to write to file %@", error);
    }
}

- (void)syncUpdateAccessDateForKey:(NSString*)key data:(NSData* (^)())lazyData
{
    NSString *path = [self pathForKey:key];
    NSDate *now = [NSDate date];
    NSDictionary* attributes = @{NSFileModificationDate : now};
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:path error:&error])
    {
        if ([fileManager fileExistsAtPath:path isDirectory:nil])
        {
            NSLog(@"Set attributes failed with error %@", error.localizedDescription);
        }
        else if (lazyData)
        { // The data was removed from disk cache but is still in memory
            NSData *data = lazyData();
            [self syncSetData:data forKey:key];
        }
    }
}

@end

@implementation NSFileManager(hnk_utils)

- (void)hnk_enumerateContentsOfDirectoryAtPath:(NSString*)path orderedByProperty:(NSString*)property ascending:(BOOL)ascending usingBlock:(void(^)(NSURL *url, NSUInteger idx, BOOL *stop))block
{
    NSURL *directoryURL = [NSURL fileURLWithPath:path];
    NSError *error;
    NSArray *contents = [self contentsOfDirectoryAtURL:directoryURL includingPropertiesForKeys:@[property] options:kNilOptions error:&error];
    if (!contents)
    {
        NSLog(@"Failed to list directory with error %@", error);
        return;
    }
    contents = [contents sortedArrayUsingComparator:^NSComparisonResult(NSURL *url1, NSURL *url2) {
        id value1;
        if ([url1 getResourceValue:&value1 forKey:property error:nil]) return ascending ? NSOrderedAscending : NSOrderedDescending;
        id value2;
        if ([url2 getResourceValue:&value2 forKey:property error:nil]) return ascending ? NSOrderedDescending : NSOrderedAscending;
        return ascending ? [value1 compare:value2] : [value2 compare:value1];
    }];
    [contents enumerateObjectsUsingBlock:block];
}

@end

@implementation NSString(hnk_utils)

- (NSString*)hnk_MD5String
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, result);
    NSMutableString *MD5String = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
    {
        [MD5String appendFormat:@"%02x",result[i]];
    }
    return MD5String;
}

- (BOOL)hnk_setValue:(NSString*)value forExtendedFileAttribute:(NSString*)attribute
{
    const char *attributeC = attribute.UTF8String;
    const char *path = self.fileSystemRepresentation;
    const char *valueC = value.UTF8String;
    const int result = setxattr(path, attributeC, valueC, strlen(valueC), 0, 0);
    return result == 0;
}

- (NSString*)hnk_stringByEscapingFilename
{
    // TODO: Add more characters to leave unescaped that are valid for paths but not for URLs
    NSString *filename = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)self, CFSTR(" \\"), CFSTR("/:"), kCFStringEncodingUTF8));
    return filename;
}

- (NSString*)hnk_valueForExtendedFileAttribute:(NSString*)attribute
{
	const char *attributeC = attribute.UTF8String;
    const char *path = self.fileSystemRepresentation;
    
	const ssize_t length = getxattr(path, attributeC, NULL, 0, 0, 0);
    
	if (length <= 0) return nil;
    
	char *buffer = malloc(length);
	getxattr(path, attributeC, buffer, length, 0, 0);
    
	NSString *value = [[NSString alloc] initWithBytes:buffer length:length encoding:NSUTF8StringEncoding];
    
	free(buffer);
    
	return value;
}

@end
