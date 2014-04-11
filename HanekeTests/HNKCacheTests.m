//
//  HNKCacheTests.m
//  Haneke
//
//  Created by Hermes Pique on 11/02/14.
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

#import <XCTest/XCTest.h>
#import "HNKCache.h"
#import "UIImage+HanekeTestUtils.h"
#import "HNKCache+HanekeTestUtils.h"
#import "XCTestCase+HanekeTestUtils.h"
#import <OCMock/OCMock.h>

@interface HNKCacheTests : XCTestCase

@end

@interface HNKTestCacheEntity : NSObject<HNKCacheEntity>

@end

@interface HNKTestCacheEntityImplementingCacheOriginalImage : HNKTestCacheEntity

@end

@interface HNKTestCacheEntityImplementingCacheOriginalData : HNKTestCacheEntity

@end

@interface HNKTestCacheEntityImplementingNone : HNKTestCacheEntity

@end

@implementation HNKCacheTests {
    HNKCache *_cache;
}

- (void)setUp
{
    _cache = [[HNKCache alloc] initWithName:@"test"];
}

- (void)testInitWithName
{
    HNKCache *cache = [[HNKCache alloc] initWithName:@"test"];
    XCTAssertNotNil(cache, @"");
}

- (void)testSharedCache
{
    HNKCache *cache1 = [HNKCache sharedCache];
    HNKCache *cache2 = [HNKCache sharedCache];
    XCTAssertEqualObjects(cache1, cache2, @"");
}

- (void)testRegisterFormat
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"format"];
    [_cache registerFormat:format];
    XCTAssertTrue(format.diskSize == 0, @"");
}

- (void)testClearFormat_Existing
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"format"];
    [_cache registerFormat:format];
    
    [_cache clearFormatNamed:format.name];
    XCTAssertTrue(format.diskSize == 0, @"");
}

- (void)testClearFormat_Inexisting
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"format"];
    [_cache clearFormatNamed:format.name];
}

- (void)testImageForEntity_OpaqueImage
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 10)];
    id entity = [HNKCache entityWithKey:@"1" data:nil image:image];
    HNKCacheFormat *format = [self registerFormatWithSize:CGSizeMake(1, 1)];
    NSError *error = nil;
    
    UIImage *result = [_cache imageForEntity:entity formatName:format.name error:&error];
    CGSize resultSize = result.size;
    
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertTrue(CGSizeEqualToSize(resultSize, format.size), @"");
    XCTAssertFalse(result.hnk_hasAlpha, @"");
}

- (void)testImageForEntity_ImageWithAlpha
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 10) opaque:NO];
    id entity = [HNKCache entityWithKey:@"1" data:nil image:image];
    HNKCacheFormat *format = [self registerFormatWithSize:CGSizeMake(1, 1)];
    NSError *error = nil;
    
    UIImage *result = [_cache imageForEntity:entity formatName:format.name error:&error];
    CGSize resultSize = result.size;
    
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertTrue(CGSizeEqualToSize(resultSize, format.size), @"");
    XCTAssertTrue(result.hnk_hasAlpha, @"");
}

- (void)testImageForEntity_ImplementingCacheOriginalImage
{
    id<HNKCacheEntity> entity = [HNKTestCacheEntityImplementingCacheOriginalImage new];
    HNKCacheFormat *format = [self registerFormatWithSize:CGSizeMake(1, 1)];
    NSError *error = nil;

    UIImage *result = [_cache imageForEntity:entity formatName:format.name error:&error];
    CGSize resultSize = result.size;
    
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertTrue(CGSizeEqualToSize(resultSize, format.size), @"");
}

- (void)testImageForEntity_ImplementingCacheOriginalData
{
    id<HNKCacheEntity> entity = [HNKTestCacheEntityImplementingCacheOriginalData new];
    HNKCacheFormat *format = [self registerFormatWithSize:CGSizeMake(1, 1)];
    NSError *error = nil;

    UIImage *result = [_cache imageForEntity:entity formatName:format.name error:&error];
    CGSize resultSize = result.size;
    
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertTrue(CGSizeEqualToSize(resultSize, format.size), @"");
}

- (void)testImageForEntity_ImplementingNone
{
    id entity = [HNKTestCacheEntityImplementingNone new];
    HNKCacheFormat *format = [self registerFormatWithSize:CGSizeMake(1, 1)];
    NSError *error = nil;

    UIImage *result = [_cache imageForEntity:entity formatName:format.name error:&error];
    
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
    XCTAssertEqualObjects(error.domain, HNKErrorDomain, @"");
    XCTAssertEqual(error.code, HNKErrorEntityMustReturnImageOrData, @"");
    XCTAssertNotNil(error.userInfo[NSLocalizedDescriptionKey], @"");
}

- (void)testImageForEntity_Data
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 10)];
    NSData *data = UIImagePNGRepresentation(image);
    id entity = [HNKCache entityWithKey:@"1" data:data image:nil];
    HNKCacheFormat *format = [self registerFormatWithSize:CGSizeMake(1, 1)];
    NSError *error = nil;

    UIImage *result = [_cache imageForEntity:entity formatName:format.name error:&error];
    CGSize resultSize = result.size;
    
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertTrue(CGSizeEqualToSize(resultSize, format.size), @"");
}

- (void)testImageForEntity_InvalidData
{
    NSData *data = [NSData data];
    id entity = [HNKCache entityWithKey:@"1" data:data image:nil];
    HNKCacheFormat *format = [self registerFormatWithSize:CGSizeMake(1, 1)];
    NSError *error = nil;
    
    UIImage *result = [_cache imageForEntity:entity formatName:format.name error:&error];
    
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
    XCTAssertEqualObjects(error.domain, HNKErrorDomain, @"");
    XCTAssertEqual(error.code, HNKErrorEntityCannotReadImageFromData, @"");
    XCTAssertNotNil(error.userInfo[NSLocalizedDescriptionKey], @"");
}

- (void)testImageForEntity_PreResizeBlock
{
    HNKCacheFormat *format = [self registerFormatWithSize:CGSizeMake(1, 1)];
    UIImage *originalImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:format.size];
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    id entity = [HNKCache entityWithKey:key data:nil image:originalImage];
    UIImage *preResizeImage = [UIImage hnk_imageWithColor:[UIColor greenColor] size:format.size];

    format.preResizeBlock = ^UIImage* (NSString *givenKey, UIImage *givenImage) {
        XCTAssertEqualObjects(givenKey, key, @"");
        XCTAssertEqualObjects(givenImage, originalImage, @"");
        return preResizeImage;
    };
    
    UIImage *result = [_cache imageForEntity:entity formatName:format.name error:nil];
    XCTAssertEqualObjects(result, preResizeImage, @"");
}

- (void)testImageForEntity_PostResizeBlock
{
    HNKCacheFormat *format = [self registerFormatWithSize:CGSizeMake(1, 1)];
    UIImage *originalImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:format.size];
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    id entity = [HNKCache entityWithKey:key data:nil image:originalImage];
    UIImage *postResizeImage = [UIImage hnk_imageWithColor:[UIColor greenColor] size:format.size];
    
    format.postResizeBlock = ^UIImage* (NSString *givenKey, UIImage *givenImage) {
        XCTAssertEqualObjects(givenKey, key, @"");
        XCTAssertEqualObjects(givenImage, originalImage, @"");
        return postResizeImage;
    };
    
    UIImage *result = [_cache imageForEntity:entity formatName:format.name error:nil];
    XCTAssertEqualObjects(result, postResizeImage, @"");
}

- (void)testRetrieveImageForEntity_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 10)];
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:@"1" data:nil image:image];
    HNKCacheFormat *format = [self registerFormatWithSize:CGSizeMake(1, 1)];
    NSString *formatName = format.name;
    [_cache setImage:image forKey:entity.cacheKey formatName:formatName];

    BOOL result = [_cache retrieveImageForEntity:entity formatName:formatName completionBlock:^(UIImage *resultImage, NSError *error) {
        XCTAssertEqualObjects(resultImage, image, @"");
        XCTAssertNil(error);
    }];
    
    XCTAssertTrue(result, @"");
}

- (void)testRetrieveImageForEntity_MemoryCacheMiss
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 10)];
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:@"1" data:nil image:image];
    HNKCacheFormat *format = [self registerFormatWithSize:CGSizeMake(1, 1)];
    NSString *formatName = format.name;
    
    BOOL result = [_cache retrieveImageForEntity:entity formatName:formatName completionBlock:^(UIImage *resultImage, NSError *error) {}];
    
    XCTAssertFalse(result, @"");
}

- (void)testRetrieveImageForEntity_PreResizeBlock_MemoryCacheMiss
{
    HNKCacheFormat *format = [self registerFormatWithSize:CGSizeMake(1, 1)];
    UIImage *originalImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:format.size];
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:key data:nil image:originalImage];
    NSString *formatName = format.name;
    
    UIImage *preResizeImage = [UIImage hnk_imageWithColor:[UIColor greenColor] size:format.size];
    
    format.preResizeBlock = ^UIImage* (NSString *givenKey, UIImage *givenImage) {
        XCTAssertEqualObjects(givenKey, key, @"");
        XCTAssertEqualObjects(givenImage, originalImage, @"");
        return preResizeImage;
    };
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        BOOL result = [_cache retrieveImageForEntity:entity formatName:formatName completionBlock:^(UIImage *resultImage, NSError *error) {
            XCTAssertEqualObjects(resultImage, preResizeImage, @"");
            XCTAssertNil(error);
            dispatch_semaphore_signal(semaphore);
        }];

        XCTAssertFalse(result, @"");
    }];
}

- (void)testRetrieveImageForEntity_PostResizeBlock_MemoryCacheMiss
{
    HNKCacheFormat *format = [self registerFormatWithSize:CGSizeMake(1, 1)];
    UIImage *originalImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:format.size];
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:key data:nil image:originalImage];
    NSString *formatName = format.name;
    
    UIImage *postResizeImage = [UIImage hnk_imageWithColor:[UIColor greenColor] size:format.size];
    
    format.preResizeBlock = ^UIImage* (NSString *givenKey, UIImage *givenImage) {
        XCTAssertEqualObjects(givenKey, key, @"");
        XCTAssertEqualObjects(givenImage, originalImage, @"");
        return postResizeImage;
    };
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        BOOL result = [_cache retrieveImageForEntity:entity formatName:formatName completionBlock:^(UIImage *resultImage, NSError *error) {
            XCTAssertEqualObjects(resultImage, postResizeImage, @"");
            XCTAssertNil(error);
            dispatch_semaphore_signal(semaphore);
        }];
        
        XCTAssertFalse(result, @"");
    }];
}

- (void)testRetrieveImageForKey_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 10)];
    HNKCacheFormat *format = [self registerFormatWithSize:CGSizeMake(1, 1)];
    NSString *formatName = format.name;
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    [_cache setImage:image forKey:key formatName:formatName];
    
    BOOL result = [_cache retrieveImageForKey:key formatName:formatName completionBlock:^(UIImage *resultImage, NSError *error) {
        XCTAssertEqualObjects(resultImage, image, @"");
        XCTAssertNil(error);
    }];
    
    XCTAssertTrue(result, @"");
}

- (void)testRetrieveImageForKey_MemoryCacheMiss
{
    HNKCacheFormat *format = [self registerFormatWithSize:CGSizeMake(1, 1)];
    NSString *formatName = format.name;
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    
    BOOL result = [_cache retrieveImageForKey:key formatName:formatName completionBlock:^(UIImage *resultImage, NSError *error) {}];
    
    XCTAssertFalse(result, @"");
}

#pragma mark Removing images

- (void)testRemoveImagesFromEntity_NoImagesNoFormats
{
    static NSString *key = @"test";
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:key data:nil image:nil];
    [_cache removeImagesOfEntity:entity];
}

- (void)testRemoveImagesFromEntity_Images
{
    HNKCacheFormat *format = [self registerFormatWithSize:CGSizeMake(1, 1)];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor whiteColor] size:CGSizeMake(2, 2)];
    static NSString *key = @"test";
    [_cache setImage:image forKey:key formatName:format.name];
    
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:key data:nil image:nil];
    [_cache removeImagesOfEntity:entity];
}

#pragma mark Notifications

- (void)testNotification_UIApplicationDidReceiveMemoryWarningNotification
{
    HNKCacheFormat *format = [self registerFormatWithSize:CGSizeMake(1, 1)];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor whiteColor] size:CGSizeMake(2, 2)];
    static NSString *key = @"test";
    [_cache setImage:image forKey:key formatName:format.name];
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:key data:nil image:image];
    UIImage *cachedImage = [_cache imageForEntity:entity formatName:format.name error:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:nil];

    UIImage *result = [_cache imageForEntity:entity formatName:format.name error:nil];
    XCTAssertNotEqualObjects(result, cachedImage, @"");
}

#pragma mark  Utils

- (HNKCacheFormat*)registerFormatWithSize:(CGSize)size
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"format"];
    format.size = size;
    [_cache registerFormat:format];
    return format;
}

@end

@implementation HNKTestCacheEntity

- (NSString*)cacheKey { return @"1"; };

@end

@implementation HNKTestCacheEntityImplementingCacheOriginalImage

- (UIImage*)cacheOriginalImage
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 10)];
    return image;
}

@end

@implementation HNKTestCacheEntityImplementingCacheOriginalData

- (NSData*)cacheOriginalData
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 10)];
    NSData *data = UIImagePNGRepresentation(image);
    return data;
}

@end

@implementation HNKTestCacheEntityImplementingNone

@end
