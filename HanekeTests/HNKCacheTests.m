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

- (void)testRetrieveImageForEntity_OpaqueImage
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 10)];
    id entity = [HNKCache entityWithKey:@"1" image:image];
    HNKCacheFormat *format = [_cache registerFormatWithSize:CGSizeMake(1, 1)];
 
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_cache retrieveImageForEntity:entity formatName:format.name completionBlock:^(UIImage *result, NSError *error) {
            CGSize resultSize = result.size;
            
            XCTAssertNotNil(result, @"");
            XCTAssertNil(error, @"");
            XCTAssertTrue(CGSizeEqualToSize(resultSize, format.size), @"");
            XCTAssertFalse(result.hnk_hasAlpha, @"");

            dispatch_semaphore_signal(semaphore);
        }];
    }];
    
}

- (void)testRetrieveImageForEntity_ImageWithAlpha
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 10) opaque:NO];
    id entity = [HNKCache entityWithKey:@"1" image:image];
    HNKCacheFormat *format = [_cache registerFormatWithSize:CGSizeMake(1, 1)];
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_cache retrieveImageForEntity:entity formatName:format.name completionBlock:^(UIImage *result, NSError *error) {
            CGSize resultSize = result.size;
            
            XCTAssertNotNil(result, @"");
            XCTAssertNil(error, @"");
            XCTAssertTrue(CGSizeEqualToSize(resultSize, format.size), @"");
            XCTAssertTrue(result.hnk_hasAlpha, @"");
            
            dispatch_semaphore_signal(semaphore);
        }];
    }];
}

- (void)testRetrieveImageForEntity
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 10)];
    id entity = [HNKCache entityWithKey:@"1" image:image];
    
    HNKCacheFormat *format = [_cache registerFormatWithSize:CGSizeMake(1, 1)];
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_cache retrieveImageForEntity:entity formatName:format.name completionBlock:^(UIImage *result, NSError *error) {
            CGSize resultSize = result.size;
            
            XCTAssertNotNil(result, @"");
            XCTAssertNil(error, @"");
            XCTAssertTrue(CGSizeEqualToSize(resultSize, format.size), @"");
            
            dispatch_semaphore_signal(semaphore);
        }];
    }];
}

- (void)testRetrieveImageForEntity_PreResizeBlock
{
    HNKCacheFormat *format = [_cache registerFormatWithSize:CGSizeMake(1, 1)];
    UIImage *originalImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:format.size];
    NSString *key = self.name;
    id entity = [HNKCache entityWithKey:key image:originalImage];
    UIImage *preResizeImage = [UIImage hnk_imageWithColor:[UIColor greenColor] size:format.size];

    format.preResizeBlock = ^UIImage* (NSString *givenKey, UIImage *givenImage) {
        XCTAssertEqualObjects(givenKey, key, @"");
        XCTAssertEqualObjects(givenImage, originalImage, @"");
        return preResizeImage;
    };
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_cache retrieveImageForEntity:entity formatName:format.name completionBlock:^(UIImage *result, NSError *error) {
            
            XCTAssertEqualObjects(result, preResizeImage, @"");
            
            dispatch_semaphore_signal(semaphore);
        }];
    }];
}

- (void)testRetrieveImageForEntity_PostResizeBlock
{
    HNKCacheFormat *format = [_cache registerFormatWithSize:CGSizeMake(1, 1)];
    UIImage *originalImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:format.size];
    NSString *key = self.name;
    id entity = [HNKCache entityWithKey:key image:originalImage];
    UIImage *postResizeImage = [UIImage hnk_imageWithColor:[UIColor greenColor] size:format.size];
    
    format.postResizeBlock = ^UIImage* (NSString *givenKey, UIImage *givenImage) {
        XCTAssertEqualObjects(givenKey, key, @"");
        XCTAssertEqualObjects(givenImage, originalImage, @"");
        return postResizeImage;
    };
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_cache retrieveImageForEntity:entity formatName:format.name completionBlock:^(UIImage *result, NSError *error) {
            
            XCTAssertEqualObjects(result, postResizeImage, @"");
            
            dispatch_semaphore_signal(semaphore);
        }];
    }];
}

- (void)testRetrieveImageForEntity_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 10)];
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:@"1" image:image];
    HNKCacheFormat *format = [_cache registerFormatWithSize:CGSizeMake(1, 1)];
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
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:@"1" image:image];
    HNKCacheFormat *format = [_cache registerFormatWithSize:CGSizeMake(1, 1)];
    NSString *formatName = format.name;
    
    BOOL result = [_cache retrieveImageForEntity:entity formatName:formatName completionBlock:^(UIImage *resultImage, NSError *error) {}];
    
    XCTAssertFalse(result, @"");
}

- (void)testRetrieveImageForEntity_PreResizeBlock_MemoryCacheMiss
{
    HNKCacheFormat *format = [_cache registerFormatWithSize:CGSizeMake(1, 1)];
    UIImage *originalImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:format.size];
    NSString *key = self.name;
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:key image:originalImage];
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
    HNKCacheFormat *format = [_cache registerFormatWithSize:CGSizeMake(1, 1)];
    UIImage *originalImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:format.size];
    NSString *key = self.name;
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:key image:originalImage];
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
    HNKCacheFormat *format = [_cache registerFormatWithSize:CGSizeMake(1, 1)];
    NSString *formatName = format.name;
    NSString *key = self.name;
    [_cache setImage:image forKey:key formatName:formatName];
    
    BOOL result = [_cache retrieveImageForKey:key formatName:formatName completionBlock:^(UIImage *resultImage, NSError *error) {
        XCTAssertEqualObjects(resultImage, image, @"");
        XCTAssertNil(error);
    }];
    
    XCTAssertTrue(result, @"");
}

- (void)testRetrieveImageForKey_MemoryCacheMiss
{
    HNKCacheFormat *format = [_cache registerFormatWithSize:CGSizeMake(1, 1)];
    NSString *formatName = format.name;
    NSString *key = self.name;
    
    BOOL result = [_cache retrieveImageForKey:key formatName:formatName completionBlock:^(UIImage *resultImage, NSError *error) {}];
    
    XCTAssertFalse(result, @"");
}

#pragma mark Removing images

- (void)testRemoveImagesOfFormatNamed_Existing
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"format"];
    [_cache registerFormat:format];
    
    [_cache removeImagesOfFormatNamed:format.name];
    XCTAssertTrue(format.diskSize == 0, @"");
}

- (void)testRemoveImagesOfFormatNamed_Inexisting
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"format"];
    [_cache removeImagesOfFormatNamed:format.name];
}

- (void)testRemoveImagesFromEntity_NoImagesNoFormats
{
    static NSString *key = @"test";
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:key image:nil];
    [_cache removeImagesOfEntity:entity];
}

- (void)testRemoveAllImages_OneFormat
{
    HNKCacheFormat *format = [_cache registerFormatWithSize:CGSizeMake(1, 1)];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor whiteColor] size:CGSizeMake(2, 2)];
    static NSString *key = @"test";
    [_cache setImage:image forKey:key formatName:format.name];
    
    [_cache removeAllImages];
    
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:key image:nil];
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_cache retrieveImageForEntity:entity formatName:format.name completionBlock:^(UIImage *result, NSError *error) {
            XCTAssertNil(result, @"");
            
            dispatch_semaphore_signal(semaphore);
        }];
    }];
}

- (void)testRemoveAllImages_TwoFormats
{
    HNKCacheFormat *format1 = [[HNKCacheFormat alloc] initWithName:@"format1"];
    format1.size = CGSizeMake(2, 2);
    [_cache registerFormat:format1];
    
    HNKCacheFormat *format2 = [[HNKCacheFormat alloc] initWithName:@"format2"];
    format2.size = CGSizeMake(10, 10);
    [_cache registerFormat:format2];

    UIImage *image = [UIImage hnk_imageWithColor:[UIColor whiteColor] size:CGSizeMake(20, 20)];
    static NSString *key = @"test";
    [_cache setImage:image forKey:key formatName:format1.name];
    [_cache setImage:image forKey:key formatName:format2.name];
    
    [_cache removeAllImages];
    
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:key image:nil];

    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_cache retrieveImageForEntity:entity formatName:format1.name completionBlock:^(UIImage *result, NSError *error) {
            XCTAssertNil(result, @"");
            
            dispatch_semaphore_signal(semaphore);
        }];
    }];
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_cache retrieveImageForEntity:entity formatName:format2.name completionBlock:^(UIImage *result, NSError *error) {
            XCTAssertNil(result, @"");
            
            dispatch_semaphore_signal(semaphore);
        }];
    }];
}

- (void)testRemoveImagesFromEntity_Images
{
    HNKCacheFormat *format = [_cache registerFormatWithSize:CGSizeMake(1, 1)];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor whiteColor] size:CGSizeMake(2, 2)];
    static NSString *key = @"test";
    [_cache setImage:image forKey:key formatName:format.name];
    
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:key image:nil];
    [_cache removeImagesOfEntity:entity];
}

#pragma mark Notifications

- (void)testNotification_UIApplicationDidReceiveMemoryWarningNotification
{
    HNKCacheFormat *format = [_cache registerFormatWithSize:CGSizeMake(1, 1)];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor whiteColor] size:CGSizeMake(2, 2)];
    static NSString *key = @"test";
    [_cache setImage:image forKey:key formatName:format.name];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:nil];

    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_cache retrieveImageForKey:key formatName:format.name completionBlock:^(UIImage *result, NSError *error) {
            XCTAssertNil(result, @"");
            
            dispatch_semaphore_signal(semaphore);
        }];
    }];
}

@end
