//
//  UIImageView+HanekeTests.m
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

#import <XCTest/XCTest.h>
#import "UIImageView+Haneke.h"
#import "UIImage+HanekeTestUtils.h"
#import "HNKCache+HanekeTestUtils.h"
#import "HNKNetworkFetcher.h"
#import "HNKDiskFetcher.h"
#import "UIView+Haneke.h"
#import "XCTestCase+HanekeTestUtils.h"
#import <OHHTTPStubs/OHHTTPStubs.h>

@interface UIImageView(HanekeTest)

@property (nonatomic, strong) id<HNKFetcher> hnk_entity;

@end

@interface UIImageView_HanekeTests : XCTestCase

@end

@implementation UIImageView_HanekeTests {
    UIImageView *_sut;
}

- (void)setUp
{
    [super setUp];
    _sut = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
}

- (void)tearDown
{
    [super tearDown];
    [_sut hnk_cancelSetImage];
    [OHHTTPStubs removeAllStubs];
    
    HNKCacheFormat *format = _sut.hnk_cacheFormat;
    [[HNKCache sharedCache] removeImagesOfFormatNamed:format.name];
}

#pragma mark cacheFormat

- (void)testCacheFormat_Default
{
    HNKCacheFormat *result = _sut.hnk_cacheFormat;
    XCTAssertNotNil(result, @"");
    XCTAssertEqual(result.allowUpscaling, YES, @"");
    XCTAssertTrue(result.compressionQuality == HNKViewFormatCompressionQuality, @"");
    XCTAssertTrue(result.diskCapacity == HNKViewFormatDiskCapacity, @"");
    XCTAssertEqual(result.scaleMode, HNKScaleModeFill, @"");
    XCTAssertTrue(CGSizeEqualToSize(result.size, _sut.bounds.size), @"");
}

- (void)testCacheFormat_UIViewContentModeScaleAspectFit
{
    _sut.contentMode = UIViewContentModeScaleAspectFit;
    HNKCacheFormat *result = _sut.hnk_cacheFormat;
    XCTAssertEqual(result.scaleMode, HNKScaleModeAspectFit, @"");
}

- (void)testCacheFormat_UIViewContentModeScaleAspectFill
{
    _sut.contentMode = UIViewContentModeScaleAspectFill;
    HNKCacheFormat *result = _sut.hnk_cacheFormat;
    XCTAssertEqual(result.scaleMode, HNKScaleModeAspectFill, @"");
}

- (void)testSetCacheFormat_Nil
{
    _sut.hnk_cacheFormat = nil;
    XCTAssertNotNil(_sut.hnk_cacheFormat, @"");
}

- (void)testSetCacheFormat_NilAfterValue
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"test"];
    _sut.hnk_cacheFormat = format;
    
    _sut.hnk_cacheFormat = nil;
    HNKCacheFormat *result = _sut.hnk_cacheFormat;
    XCTAssertNotNil(result, @"");
    XCTAssertNotEqualObjects(result, format, @"");
}

- (void)testSetCacheFormat_Value
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"test"];
    _sut.hnk_cacheFormat = format;
    
    HNKCacheFormat *result = _sut.hnk_cacheFormat;
    XCTAssertEqualObjects(result, format, @"");
}

#pragma mark setImage:

- (void)testSetImageWithKey_MemoryCacheMiss
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = self.name;
    
    [_sut hnk_setImage:image withKey:key];

    XCTAssertEqualObjects(_sut.hnk_entity.cacheKey, key,  @"");
    XCTAssertNil(_sut.image, @"");
}

- (void)testSetImageWithKey_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = self.name;
    HNKCacheFormat *format = _sut.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_sut hnk_setImage:image withKey:key];

    XCTAssertNil(_sut.hnk_entity,  @"");
    XCTAssertEqualObjects(_sut.image, image, @"");
}

- (void)testSetImageWithKey_ImageSet_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    _sut.image = previousImage;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = self.name;
    
    [_sut hnk_setImage:image withKey:key];
    
    XCTAssertEqualObjects(_sut.hnk_entity.cacheKey, key,  @"");
    XCTAssertEqualObjects(_sut.image, previousImage, @"");
}

- (void)testSetImageWithKeyPlaceholder_MemoryCacheMiss
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    UIImage *placeholder = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    NSString *key = self.name;
    
    [_sut hnk_setImage:image withKey:key placeholder:placeholder];
    
    XCTAssertEqualObjects(_sut.hnk_entity.cacheKey, key,  @"");
    XCTAssertEqualObjects(_sut.image, placeholder, @"");
}

- (void)testSetImageWithKeyPlaceholder_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    UIImage *placeholder = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = self.name;
    HNKCacheFormat *format = _sut.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_sut hnk_setImage:image withKey:key placeholder:placeholder];
    
    XCTAssertNil(_sut.hnk_entity, @"");
    UIImage *result = _sut.image;
    XCTAssertEqualObjects(image, result, @"");
}

- (void)testSetImageWithKeyPlaceholder_ImageSet_NilPlaceholder_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _sut.image = previousImage;
    NSString *key = self.name;
    
    [_sut hnk_setImage:image withKey:key];
    
    XCTAssertEqualObjects(_sut.hnk_entity.cacheKey, key,  @"");
    UIImage *result = _sut.image;
    XCTAssertEqualObjects(result, previousImage, @"");
}

- (void)testSetImageWithKeyPlaceholderSuccessFailure_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    HNKCacheFormat *format = _sut.hnk_cacheFormat;
    NSString *key = self.name;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    __block BOOL success = NO;
    [_sut hnk_setImage:image withKey:key placeholder:nil success:^(UIImage *result) {
        XCTAssertEqualObjects(result, image, @"");
        success = YES;
    } failure:^(NSError *error) {
        XCTFail(@"");
    }];
    
    XCTAssertTrue(success, @"");
    XCTAssertNil(_sut.hnk_entity, @"");
    XCTAssertNil(_sut.image, @"");
}

- (void)testSetImageWithKeyPlaceholderSuccessFailure_SuccessNil_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    NSString *key = self.name;
    HNKCacheFormat *format = _sut.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_sut hnk_setImage:image withKey:key placeholder:nil success:nil failure:^(NSError *error) {
        XCTFail(@"");
    }];
    
    XCTAssertNil(_sut.hnk_entity, @"");
    UIImage *result = _sut.image;
    XCTAssertEqualObjects(result, image, @"");
}

- (void)testSetImageWithKeyPlaceholderSuccessFailure_MemoryCacheMiss
{
    NSString *key = self.name;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];

    [_sut hnk_setImage:image withKey:key placeholder:nil success:nil failure:nil];
    
    XCTAssertEqualObjects(_sut.hnk_entity.cacheKey, key,  @"");
    XCTAssertNil(_sut.image, @"");
}

- (void)testSetImageWithKeyPlaceholderSuccessFailure_ImageSet_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _sut.image = previousImage;
    NSString *key = self.name;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];

    [_sut hnk_setImage:image withKey:key placeholder:nil success:nil failure:nil];
    
    XCTAssertEqualObjects(_sut.hnk_entity.cacheKey, key,  @"");
    UIImage *result = _sut.image;
    XCTAssertEqualObjects(result, previousImage, @"");
}

#pragma mark setImageFromFile:

- (void)testSetImageFromFile_MemoryCacheMiss
{
    NSString *path = [self fixturePathWithName:@"image.png"];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    [UIImagePNGRepresentation(image) writeToFile:path atomically:YES];

    [_sut hnk_setImageFromFile:path];

    HNKDiskFetcher *entity = [[HNKDiskFetcher alloc] initWithPath:path];
    XCTAssertEqualObjects(_sut.hnk_entity.cacheKey, entity.cacheKey,  @"");
    XCTAssertNil(_sut.image, @"");
    
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

- (void)testSetImageFromFile_ImageSet_MemoryCacheMiss
{
    NSString *path = [self fixturePathWithName:@"image.png"];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    [UIImagePNGRepresentation(image) writeToFile:path atomically:YES];
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _sut.image = previousImage;
    
    [_sut hnk_setImageFromFile:path];

    HNKDiskFetcher *entity = [[HNKDiskFetcher alloc] initWithPath:path];
    XCTAssertEqualObjects(_sut.hnk_entity.cacheKey, entity.cacheKey,  @"");
    XCTAssertEqualObjects(_sut.image, previousImage, @"");
    
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

- (void)testSetImageFromFile_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = [self fixturePathWithName:@"image.png"];
    HNKCacheFormat *format = _sut.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_sut hnk_setImageFromFile:key];
    
    XCTAssertNil(_sut.hnk_entity, @"");
    UIImage *result = _sut.image;
    XCTAssertEqualObjects(image, result, @"");
}

- (void)testSetImageFromFileplaceholder_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    UIImage *placeholder = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = [self fixturePathWithName:@"image.png"];
    HNKCacheFormat *format = _sut.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_sut hnk_setImageFromFile:key placeholder:placeholder];
    
    XCTAssertNil(_sut.hnk_entity, @"");
    UIImage *result = _sut.image;
    XCTAssertEqualObjects(result, image, @"");
}

- (void)testSetImageFromFilePlaceholder_MemoryCacheMiss
{
    UIImage *placeholder = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *path = [self fixturePathWithName:@"image.png"];

    [_sut hnk_setImageFromFile:path placeholder:placeholder];
    
    HNKDiskFetcher *entity = [[HNKDiskFetcher alloc] initWithPath:path];
    XCTAssertEqualObjects(_sut.hnk_entity.cacheKey, entity.cacheKey,  @"");
    UIImage *result = _sut.image;
    XCTAssertEqualObjects(result, placeholder, @"");
}

- (void)testSetImageFromFilePlaceholder_ImageSet_NilPlaceholder_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _sut.image = previousImage;
    NSString *path = [self fixturePathWithName:@"image.png"];
    
    [_sut hnk_setImageFromFile:path placeholder:nil];
    
    HNKDiskFetcher *entity = [[HNKDiskFetcher alloc] initWithPath:path];
    XCTAssertEqualObjects(_sut.hnk_entity.cacheKey, entity.cacheKey,  @"");
    UIImage *result = _sut.image;
    XCTAssertEqualObjects(result, previousImage, @"");
}

- (void)testSetImageFromFilePlaceholderSuccessFailure_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    NSString *key = [self fixturePathWithName:@"image.png"];
    HNKCacheFormat *format = _sut.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_sut hnk_setImageFromFile:key placeholder:nil success:^(UIImage *result) {
        XCTAssertEqualObjects(result, image, @"");
    } failure:^(NSError *error) {
        XCTFail(@"");
    }];
    XCTAssertNil(_sut.hnk_entity, @"");
    XCTAssertNil(_sut.image, @"");
}

- (void)testSetImageFromFilePlaceholderSuccessFailure_SuccessNil_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    NSString *key = [self fixturePathWithName:@"image.png"];
    HNKCacheFormat *format = _sut.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_sut hnk_setImageFromFile:key placeholder:nil success:nil failure:^(NSError *error) {
        XCTFail(@"");
    }];
    
    XCTAssertNil(_sut.hnk_entity, @"");
    UIImage *result = _sut.image;
    XCTAssertEqualObjects(result, image, @"");
}

- (void)testSetImageFromFilePlaceholderSuccessFailure_MemoryCacheMiss
{
    NSString *path = [self fixturePathWithName:@"image.png"];
    
    [_sut hnk_setImageFromFile:path placeholder:nil success:nil failure:nil];
    
    HNKDiskFetcher *entity = [[HNKDiskFetcher alloc] initWithPath:path];
    XCTAssertEqualObjects(_sut.hnk_entity.cacheKey, entity.cacheKey,  @"");
    XCTAssertNil(_sut.image, @"");
}

- (void)testSetImageFromFilePlaceholderSuccessFailure_ImageSet_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _sut.image = previousImage;
    NSString *path = [self fixturePathWithName:@"image.png"];
    
    [_sut hnk_setImageFromFile:path placeholder:nil success:nil failure:nil];
    
    HNKDiskFetcher *entity = [[HNKDiskFetcher alloc] initWithPath:path];
    XCTAssertEqualObjects(_sut.hnk_entity.cacheKey, entity.cacheKey,  @"");
    UIImage *result = _sut.image;
    XCTAssertEqualObjects(result, previousImage, @"");
}

- (void)testSetImageFromFilePlaceholderSuccessFailure_NoSuchFileError
{
    NSString *key = [self fixturePathWithName:@"image.png"];
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_sut hnk_setImageFromFile:key placeholder:nil success:^(UIImage *result) {
            XCTFail(@"");
            dispatch_semaphore_signal(semaphore);
        } failure:^(NSError *error) {
            XCTAssertNotNil(error);
            XCTAssertEqual(error.code, NSFileReadNoSuchFileError, @"");
            dispatch_semaphore_signal(semaphore);
        }];
    }];
    
    XCTAssertNil(_sut.hnk_entity, @"");
}

- (void)testSetImageFromFilePlaceholderSuccessFailure_InvalidData
{
    NSString *path = [self fixturePathWithName:@"image.png"];
    NSData *data = [@"Hello" dataUsingEncoding:NSUTF8StringEncoding];
    [data writeToFile:path atomically:YES];
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_sut hnk_setImageFromFile:path placeholder:nil success:^(UIImage *result) {
            XCTFail(@"hnk_setImageFromFile succeded with invalid data");
            dispatch_semaphore_signal(semaphore);
         } failure:^(NSError *error) {
            XCTAssertNotNil(error);
            XCTAssertEqualObjects(error.domain, HNKErrorDomain, @"");
            XCTAssertEqual(error.code, HNKErrorDiskFetcherInvalidData, @"");
            dispatch_semaphore_signal(semaphore);
        }];

        HNKDiskFetcher *entity = [[HNKDiskFetcher alloc] initWithPath:path];
        XCTAssertEqualObjects(_sut.hnk_entity.cacheKey, entity.cacheKey,  @"");
    }];
    
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

#pragma mark setImageFromEntity:

- (void)testSetImageFromEntity_MemoryCacheMiss
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = self.name;
    id<HNKFetcher> entity = [HNKCache fetcherWithKey:key image:image];
    [_sut hnk_setImageFromEntity:entity];
    
    XCTAssertEqualObjects(_sut.hnk_entity, entity,  @"");
    XCTAssertNil(_sut.image, @"");
}

- (void)testSetImageFromEntity_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = @"test";
    HNKCacheFormat *format = _sut.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    id<HNKFetcher> entity = [HNKCache fetcherWithKey:key image:image];
    
    [_sut hnk_setImageFromEntity:entity];
    
    XCTAssertNil(_sut.hnk_entity, @"");
    UIImage *result = _sut.image;
    XCTAssertEqualObjects(image, result, @"");
}

- (void)testSetImageFromEntity_ImageSet_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    _sut.image = previousImage;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = self.name;
    id<HNKFetcher> entity = [HNKCache fetcherWithKey:key image:image];
    
    [_sut hnk_setImageFromEntity:entity];
    
    XCTAssertEqualObjects(_sut.hnk_entity, entity,  @"");
    XCTAssertEqualObjects(_sut.image, previousImage, @"");
}

- (void)testSetImageFromEntityPlaceholder_MemoryCacheMiss
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    UIImage *placeholder = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = self.name;
    id<HNKFetcher> entity = [HNKCache fetcherWithKey:key image:image];
    
    [_sut hnk_setImageFromEntity:entity placeholder:placeholder];
    
    XCTAssertEqualObjects(_sut.hnk_entity, entity,  @"");
    XCTAssertEqualObjects(_sut.image, placeholder, @"");
}

- (void)testSetImageFromEntityPlaceholder_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    UIImage *placeholder = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = @"test";
    HNKCacheFormat *format = _sut.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    id<HNKFetcher> entity = [HNKCache fetcherWithKey:key image:image];
    
    [_sut hnk_setImageFromEntity:entity placeholder:placeholder];
    
    XCTAssertNil(_sut.hnk_entity, @"");
    UIImage *result = _sut.image;
    XCTAssertEqualObjects(image, result, @"");
}

- (void)testSetImageFromEntity_ImageSet_NilPlaceholder_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _sut.image = previousImage;
    NSString *key = self.name;
    id<HNKFetcher> entity = [HNKCache fetcherWithKey:key image:image];
    
    [_sut hnk_setImageFromEntity:entity placeholder:nil];
    
    XCTAssertEqualObjects(_sut.hnk_entity, entity,  @"");
    UIImage *result = _sut.image;
    XCTAssertEqualObjects(result, previousImage, @"");
}

#pragma mark setImageFromURL:

- (void)testSetImageFromURL_MemoryCacheMiss
{
    NSURL *url = [NSURL URLWithString:@"http://imgs.xkcd.com/comics/election.png"];
    
    [_sut hnk_setImageFromURL:url];
    
    id<HNKFetcher> entity = [[HNKNetworkFetcher alloc] initWithURL:url];
    XCTAssertEqualObjects(_sut.hnk_entity.cacheKey, entity.cacheKey,  @"");
    XCTAssertNil(_sut.image, @"");
}

- (void)testSetImageFromURL_ImageSet_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _sut.image = previousImage;
    NSURL *url = [NSURL URLWithString:@"http://imgs.xkcd.com/comics/election.png"];

    [_sut hnk_setImageFromURL:url];
    
    id<HNKFetcher> entity = [[HNKNetworkFetcher alloc] initWithURL:url];
    XCTAssertEqualObjects(_sut.hnk_entity.cacheKey, entity.cacheKey,  @"");
    XCTAssertEqualObjects(_sut.image, previousImage, @"");
}

- (void)testSetImageFromURL_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = @"http://imgs.xkcd.com/comics/election.png";
    HNKCacheFormat *format = _sut.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    NSURL *url = [NSURL URLWithString:key];
    
    [_sut hnk_setImageFromURL:url];
    
    XCTAssertNil(_sut.hnk_entity, @"");
    UIImage *result = _sut.image;
    XCTAssertEqualObjects(image, result, @"");
}

- (void)testSetImageFromURLPlaceholder_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    UIImage *placeholder = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = @"http://imgs.xkcd.com/comics/election.png";
    HNKCacheFormat *format = _sut.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    NSURL *url = [NSURL URLWithString:key];
    
    [_sut hnk_setImageFromURL:url placeholder:placeholder];
    
    XCTAssertNil(_sut.hnk_entity, @"");
    UIImage *result = _sut.image;
    XCTAssertEqualObjects(result, image, @"");
}

- (void)testSetImageFromURLPlaceholder_MemoryCacheMiss
{
    UIImage *placeholder = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = @"http://imgs.xkcd.com/comics/election.png";
    NSURL *url = [NSURL URLWithString:key];
    
    [_sut hnk_setImageFromURL:url placeholder:placeholder];
    
    id<HNKFetcher> entity = [[HNKNetworkFetcher alloc] initWithURL:url];
    XCTAssertEqualObjects(_sut.hnk_entity.cacheKey, entity.cacheKey,  @"");
    UIImage *result = _sut.image;
    XCTAssertEqualObjects(result, placeholder, @"");
}

- (void)testSetImageFromURLPlaceholder_ImageSet_NilPlaceholder_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _sut.image = previousImage;
    NSString *key = @"http://imgs.xkcd.com/comics/election.png";
    NSURL *url = [NSURL URLWithString:key];
    
    [_sut hnk_setImageFromURL:url placeholder:nil];
    
    id<HNKFetcher> entity = [[HNKNetworkFetcher alloc] initWithURL:url];
    XCTAssertEqualObjects(_sut.hnk_entity.cacheKey, entity.cacheKey,  @"");
    UIImage *result = _sut.image;
    XCTAssertEqualObjects(result, previousImage, @"");
}

- (void)testSetImageFromURLPlaceholderSuccessFailure_MemoryCacheMiss
{
    NSURL *url = [NSURL URLWithString:@"http://imgs.xkcd.com/comics/election.png"];
    
    [_sut hnk_setImageFromURL:url placeholder:nil success:nil failure:nil];
    
    id<HNKFetcher> entity = [[HNKNetworkFetcher alloc] initWithURL:url];
    XCTAssertEqualObjects(_sut.hnk_entity.cacheKey, entity.cacheKey,  @"");
    XCTAssertNil(_sut.image, @"");
}

- (void)testSetImageFromURLPlaceholderSuccessFailure_ImageSet_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _sut.image = previousImage;
    NSURL *url = [NSURL URLWithString:@"http://imgs.xkcd.com/comics/election.png"];
    
    [_sut hnk_setImageFromURL:url placeholder:nil success:nil failure:nil];
    
    id<HNKFetcher> entity = [[HNKNetworkFetcher alloc] initWithURL:url];
    XCTAssertEqualObjects(_sut.hnk_entity.cacheKey, entity.cacheKey,  @"");
    UIImage *result = _sut.image;
    XCTAssertEqualObjects(result, previousImage, @"");
}

- (void)testSetImageFromURLPlaceholderSuccessFailure_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = @"http://imgs.xkcd.com/comics/election.png";
    HNKCacheFormat *format = _sut.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    NSURL *url = [NSURL URLWithString:key];
    
    [_sut hnk_setImageFromURL:url placeholder:nil success:^(UIImage *result) {
        XCTAssertEqualObjects(result, image, @"");
    } failure:^(NSError *error) {
        XCTFail(@"");
    }];
    
    XCTAssertNil(_sut.hnk_entity, @"");
    XCTAssertNil(_sut.image, @"");
}

- (void)testSetImageFromURLPlaceholderSuccessFailure_SuccesNil_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = @"http://imgs.xkcd.com/comics/election.png";
    HNKCacheFormat *format = _sut.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    NSURL *url = [NSURL URLWithString:key];
    
    [_sut hnk_setImageFromURL:url placeholder:nil success:nil failure:^(NSError *error) {
        XCTFail(@"");
    }];
    
    XCTAssertNil(_sut.hnk_entity, @"");
    UIImage *result = _sut.image;
    XCTAssertEqualObjects(result, image, @"");
}

- (void)testSetImageFromURLPlaceholderSuccessFailure_DownloadSuccess
{
    NSURL *URL = [NSURL URLWithString:@"http://haneke.com/image.jpg"];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:URL.absoluteString];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        UIImage *image = [UIImage hnk_imageWithColor:[UIColor whiteColor] size:CGSizeMake(5, 5)];
        NSData *data = UIImageJPEGRepresentation(image, 1);
        return [OHHTTPStubsResponse responseWithData:data statusCode:200 headers:nil];
    }];
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore)
     {
         [_sut hnk_setImageFromURL:URL placeholder:nil success:^(UIImage *image) {
             dispatch_semaphore_signal(semaphore);
         } failure:^(NSError *error) {
             XCTFail(@"");
             dispatch_semaphore_signal(semaphore);
         }];
     }];
}

- (void)testSetImageFromURLPlaceholderSuccessFailure_DownloadFailure
{
    NSURL *URL = [NSURL URLWithString:@"http://haneke.com/image.jpg"];
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:URL.absoluteString];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithError:error];
    }];
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore)
     {
         [_sut hnk_setImageFromURL:URL placeholder:nil success:^(UIImage *image) {
             XCTFail(@"");
             dispatch_semaphore_signal(semaphore);
         } failure:^(NSError *result) {
             dispatch_semaphore_signal(semaphore);
             XCTAssertNotNil(error, @"");
             XCTAssertEqual(error.code, result.code, @"");
         }];
     }];
}

- (void)testSetImageFromURLSuccessFailure_DownloadMissingData
{
    NSURL *URL = [NSURL URLWithString:@"http://haneke.com/image.jpg"];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:URL.absoluteString];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        
        UIImage *image = [UIImage hnk_imageWithColor:[UIColor whiteColor] size:CGSizeMake(5, 5)];
        NSData *data = UIImageJPEGRepresentation(image, 1);
        NSString *contentLengthString = [NSString stringWithFormat:@"%ld", (long)data.length * 10];
        OHHTTPStubsResponse *response = [OHHTTPStubsResponse responseWithData:data statusCode:200 headers:nil];
        response.httpHeaders = @{@"Content-Length": contentLengthString}; // See: https://github.com/AliSoftware/OHHTTPStubs/pull/62
        return response;
    }];
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore)
     {
         [_sut hnk_setImageFromURL:URL placeholder:nil success:^(UIImage *image) {
             XCTFail(@"");
             dispatch_semaphore_signal(semaphore);
         } failure:^(NSError *error) {
             dispatch_semaphore_signal(semaphore);
             XCTAssertNotNil(error, @"");
             XCTAssertEqual(HNKErrorNetworkFetcherMissingData, error.code, @"");
         }];
     }];
}

#pragma mark cancelSetImage

- (void)testCancelSetImage_NoRequest
{
    [_sut hnk_cancelSetImage];

    XCTAssertNil(_sut.hnk_entity, @"");
}

- (void)testCancelSetImage_After
{
    NSURL *url = [NSURL URLWithString:@"http://imgs.xkcd.com/comics/election.png"];
    [_sut hnk_setImageFromURL:url placeholder:nil success:^(UIImage *image) {
        XCTFail(@"Unexpected success");
    } failure:^(NSError *error) {
        XCTFail(@"Unexpected success");
    }];
    
    [_sut hnk_cancelSetImage];

    XCTAssertNil(_sut.hnk_entity, @"");
    [self hnk_waitFor:0.1];
}

#pragma mark Utils

- (NSString*)fixturePathWithName:(NSString*)name
{
    NSString *directory = NSHomeDirectory();
    NSString *path = [directory stringByAppendingPathComponent:@"HanekeTests"];
    path = [directory stringByAppendingPathComponent:@"fixtures"];
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    path = [directory stringByAppendingPathComponent:name];
    return path;
}

@end
