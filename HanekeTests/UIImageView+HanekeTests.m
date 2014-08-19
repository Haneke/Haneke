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
#import "XCTestCase+HanekeTestUtils.h"
#import <OHHTTPStubs/OHHTTPStubs.h>

@interface UIImageView(HanekeTest)

@property (nonatomic, strong) NSString *hnk_requestedCacheKey;
@property (nonatomic, strong) NSString *hnk_entity;

@end

@interface UIImageView_HanekeTests : XCTestCase

@end

@implementation UIImageView_HanekeTests {
    UIImageView *_imageView;
}

- (void)setUp
{
    [super setUp];
    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
}

- (void)tearDown
{
    [super tearDown];
    [_imageView hnk_cancelImageRequest];
    [OHHTTPStubs removeAllStubs];
    
    HNKCacheFormat *format = _imageView.hnk_cacheFormat;
    [[HNKCache sharedCache] removeImagesOfFormatNamed:format.name];
}

#pragma mark cacheFormat

- (void)testCacheFormat_Default
{
    HNKCacheFormat *result = _imageView.hnk_cacheFormat;
    XCTAssertNotNil(result, @"");
    XCTAssertEqual(result.allowUpscaling, YES, @"");
    XCTAssertTrue(result.compressionQuality == 0.75, @"");
    XCTAssertTrue(result.diskCapacity == 10 * 1024 * 1024, @"");
    XCTAssertEqual(result.scaleMode, HNKScaleModeFill, @"");
    XCTAssertTrue(CGSizeEqualToSize(result.size, _imageView.bounds.size), @"");
}

- (void)testCacheFormat_UIViewContentModeScaleAspectFit
{
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    HNKCacheFormat *result = _imageView.hnk_cacheFormat;
    XCTAssertEqual(result.scaleMode, HNKScaleModeAspectFit, @"");
}

- (void)testCacheFormat_UIViewContentModeScaleAspectFill
{
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    HNKCacheFormat *result = _imageView.hnk_cacheFormat;
    XCTAssertEqual(result.scaleMode, HNKScaleModeAspectFill, @"");
}

- (void)testCacheFormat_AnotherUIViewContentMode
{
    _imageView.contentMode = UIViewContentModeCenter;
    HNKCacheFormat *result = _imageView.hnk_cacheFormat;
    XCTAssertEqual(result.scaleMode, HNKScaleModeFill, @"");
}

- (void)testSetCacheFormat_Nil
{
    _imageView.hnk_cacheFormat = nil;
    XCTAssertNotNil(_imageView.hnk_cacheFormat, @"");
}

- (void)testSetCacheFormat_NilAfterValue
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"test"];
    _imageView.hnk_cacheFormat = format;
    
    _imageView.hnk_cacheFormat = nil;
    HNKCacheFormat *result = _imageView.hnk_cacheFormat;
    XCTAssertNotNil(result, @"");
    XCTAssertNotEqualObjects(result, format, @"");
}

- (void)testSetCacheFormat_Value
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"test"];
    _imageView.hnk_cacheFormat = format;
    
    HNKCacheFormat *result = _imageView.hnk_cacheFormat;
    XCTAssertEqualObjects(result, format, @"");
}

#pragma mark setImage:

- (void)testSetImageWithKey_MemoryCacheMiss
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];

    [_imageView hnk_setImage:image withKey:key];

    XCTAssertEqualObjects(_imageView.hnk_requestedCacheKey, key,  @"");
    XCTAssertNil(_imageView.image, @"");
}

- (void)testSetImageWithKey_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    HNKCacheFormat *format = _imageView.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_imageView hnk_setImage:image withKey:key];

    XCTAssertNil(_imageView.hnk_requestedCacheKey, @"");
    XCTAssertEqualObjects(_imageView.image, image, @"");
}

- (void)testSetImageWithKey_ImageSet_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    _imageView.image = previousImage;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    
    [_imageView hnk_setImage:image withKey:key];
    
    XCTAssertEqualObjects(_imageView.hnk_requestedCacheKey, key,  @"");
    XCTAssertEqualObjects(_imageView.image, previousImage, @"");
}

- (void)testSetImageWithKeyPlaceholderImage_MemoryCacheMiss
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    UIImage *placeholderImage = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    
    [_imageView hnk_setImage:image withKey:key placeholderImage:placeholderImage];
    
    XCTAssertEqualObjects(_imageView.hnk_requestedCacheKey, key,  @"");
    XCTAssertEqualObjects(_imageView.image, placeholderImage, @"");
}

- (void)testSetImageWithKeyPlaceholderImage_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    UIImage *placeholderImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    HNKCacheFormat *format = _imageView.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_imageView hnk_setImage:image withKey:key placeholderImage:placeholderImage];
    
    XCTAssertNil(_imageView.hnk_requestedCacheKey, @"");
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(image, result, @"");
}

- (void)testSetImageWithKeyPlaceholderImage_ImageSet_NilPlaceholder_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _imageView.image = previousImage;
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    
    [_imageView hnk_setImage:image withKey:key];
    
    XCTAssertEqualObjects(_imageView.hnk_requestedCacheKey, key,  @"");
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, previousImage, @"");
}

- (void)testSetImageWithKeySuccessFailure_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    HNKCacheFormat *format = _imageView.hnk_cacheFormat;
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_imageView hnk_setImage:image withKey:key success:^(UIImage *result) {
        XCTAssertEqualObjects(result, image, @"");
    } failure:^(NSError *error) {
        XCTFail(@"");
    }];
    XCTAssertNil(_imageView.hnk_requestedCacheKey, @"");
    XCTAssertNil(_imageView.image, @"");
}

- (void)testSetImageWithKeySuccessFailure_SuccessNil_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    HNKCacheFormat *format = _imageView.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_imageView hnk_setImage:image withKey:key success:nil failure:^(NSError *error) {
        XCTFail(@"");
    }];
    
    XCTAssertNil(_imageView.hnk_requestedCacheKey, @"");
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, image, @"");
}

- (void)testSetImageWithKeySuccessFailure_MemoryCacheMiss
{
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];

    [_imageView hnk_setImage:image withKey:key success:nil failure:nil];
    
    XCTAssertEqualObjects(_imageView.hnk_requestedCacheKey, key,  @"");
    XCTAssertNil(_imageView.image, @"");
}

- (void)testSetImageWithKeySuccessFailure_ImageSet_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _imageView.image = previousImage;
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];

    [_imageView hnk_setImage:image withKey:key success:nil failure:nil];
    
    XCTAssertEqualObjects(_imageView.hnk_requestedCacheKey, key,  @"");
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, previousImage, @"");
}

#pragma mark setImageFromFile:

- (void)testSetImageFromFile_MemoryCacheMiss
{
    NSString *path = [self fixturePathWithName:@"image.png"];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    [UIImagePNGRepresentation(image) writeToFile:path atomically:YES];

    XCTAssertNil(_imageView.hnk_requestedCacheKey, @"");
    [_imageView hnk_setImageFromFile:path];
    XCTAssertNil(_imageView.image, @"");
    
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

- (void)testSetImageFromFile_ImageSet_MemoryCacheMiss
{
    NSString *path = [self fixturePathWithName:@"image.png"];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    [UIImagePNGRepresentation(image) writeToFile:path atomically:YES];
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _imageView.image = previousImage;
    
    [_imageView hnk_setImageFromFile:path];

    XCTAssertEqualObjects(_imageView.hnk_requestedCacheKey, path,  @"");
    XCTAssertEqualObjects(_imageView.image, previousImage, @"");
    
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

- (void)testSetImageFromFile_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = [self fixturePathWithName:@"image.png"];
    HNKCacheFormat *format = _imageView.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_imageView hnk_setImageFromFile:key];
    
    XCTAssertNil(_imageView.hnk_requestedCacheKey, @"");
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(image, result, @"");
}

- (void)testSetImageFromFilePlaceholderImage_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    UIImage *placeholderImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = [self fixturePathWithName:@"image.png"];
    HNKCacheFormat *format = _imageView.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_imageView hnk_setImageFromFile:key placeholderImage:placeholderImage];
    
    XCTAssertNil(_imageView.hnk_requestedCacheKey, @"");
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, image, @"");
}

- (void)testSetImageFromFilePlaceholderImage_MemoryCacheMiss
{
    UIImage *placeholderImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = [self fixturePathWithName:@"image.png"];

    [_imageView hnk_setImageFromFile:key placeholderImage:placeholderImage];
    
    XCTAssertEqualObjects(_imageView.hnk_requestedCacheKey, key,  @"");
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, placeholderImage, @"");
}

- (void)testSetImageFromFilePlaceholderImage_ImageSet_NilPlaceholder_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _imageView.image = previousImage;
    NSString *key = [self fixturePathWithName:@"image.png"];
    
    [_imageView hnk_setImageFromFile:key placeholderImage:nil];
    
    XCTAssertEqualObjects(_imageView.hnk_requestedCacheKey, key,  @"");
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, previousImage, @"");
}

- (void)testSetImageFromFileSuccessFailure_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    NSString *key = [self fixturePathWithName:@"image.png"];
    HNKCacheFormat *format = _imageView.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_imageView hnk_setImageFromFile:key success:^(UIImage *result) {
        XCTAssertEqualObjects(result, image, @"");
    } failure:^(NSError *error) {
        XCTFail(@"");
    }];
    XCTAssertNil(_imageView.hnk_requestedCacheKey, @"");
    XCTAssertNil(_imageView.image, @"");
}

- (void)testSetImageFromFileSuccessFailure_SuccessNil_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    NSString *key = [self fixturePathWithName:@"image.png"];
    HNKCacheFormat *format = _imageView.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_imageView hnk_setImageFromFile:key success:nil failure:^(NSError *error) {
        XCTFail(@"");
    }];
    
    XCTAssertNil(_imageView.hnk_requestedCacheKey, @"");
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, image, @"");
}

- (void)testSetImageFromFileSuccessFailure_MemoryCacheMiss
{
    NSString *key = [self fixturePathWithName:@"image.png"];
    
    [_imageView hnk_setImageFromFile:key success:nil failure:nil];
    
    XCTAssertEqualObjects(_imageView.hnk_requestedCacheKey, key,  @"");
    XCTAssertNil(_imageView.image, @"");
}

- (void)testSetImageFromFileSuccessFailure_ImageSet_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _imageView.image = previousImage;
    NSString *key = [self fixturePathWithName:@"image.png"];
    
    [_imageView hnk_setImageFromFile:key success:nil failure:nil];
    
    XCTAssertEqualObjects(_imageView.hnk_requestedCacheKey, key,  @"");
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, previousImage, @"");
}

- (void)testSetImageFromFileSuccessFailure_NoSuchFileError
{
    NSString *key = [self fixturePathWithName:@"image.png"];
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_imageView hnk_setImageFromFile:key success:^(UIImage *result) {
            XCTFail(@"");
            dispatch_semaphore_signal(semaphore);
        } failure:^(NSError *error) {
            XCTAssertNotNil(error);
            XCTAssertEqual(error.code, NSFileReadNoSuchFileError, @"");
            dispatch_semaphore_signal(semaphore);
        }];
    }];
    
    XCTAssertNil(_imageView.hnk_requestedCacheKey, @"");
}

- (void)testSetImageFromFileSuccessFailure_InvalidData
{
    NSString *path = [self fixturePathWithName:@"image.png"];
    NSData *data = [NSData data];
    [data writeToFile:path atomically:YES];
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_imageView hnk_setImageFromFile:path success:^(UIImage *result) {
            XCTFail(@"hnk_setImageFromFile succeded with invalid data");
            dispatch_semaphore_signal(semaphore);
         } failure:^(NSError *error) {
            XCTAssertNotNil(error);
            XCTAssertEqualObjects(error.domain, HNKErrorDomain, @"");
            XCTAssertEqual(error.code, HNKErrorEntityMustReturnImage, @"");
            dispatch_semaphore_signal(semaphore);
        }];
    }];
    
    XCTAssertNil(_imageView.hnk_requestedCacheKey, @"");
    
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

#pragma mark setImageFromEntity:

- (void)testSetImageFromEntity_MemoryCacheMiss
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:key image:image];
    [_imageView hnk_setImageFromEntity:entity];
    
    XCTAssertEqualObjects(_imageView.hnk_requestedCacheKey, key,  @"");
    XCTAssertNil(_imageView.image, @"");
}

- (void)testSetImageFromEntity_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = @"test";
    HNKCacheFormat *format = _imageView.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:key image:image];
    
    [_imageView hnk_setImageFromEntity:entity];
    
    XCTAssertNil(_imageView.hnk_requestedCacheKey, @"");
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(image, result, @"");
}

- (void)testSetImageFromEntity_ImageSet_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    _imageView.image = previousImage;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:key image:image];
    
    [_imageView hnk_setImageFromEntity:entity];
    
    XCTAssertEqualObjects(_imageView.hnk_requestedCacheKey, key,  @"");
    XCTAssertEqualObjects(_imageView.image, previousImage, @"");
}

- (void)testSetImageFromEntityPlaceholderImage_MemoryCacheMiss
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    UIImage *placeholderImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:key image:image];
    
    [_imageView hnk_setImageFromEntity:entity placeholderImage:placeholderImage];
    
    XCTAssertEqualObjects(_imageView.hnk_requestedCacheKey, key,  @"");
    XCTAssertEqualObjects(_imageView.image, placeholderImage, @"");
}

- (void)testSetImageFromEntityPlaceholderImage_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    UIImage *placeholderImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = @"test";
    HNKCacheFormat *format = _imageView.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:key image:image];
    
    [_imageView hnk_setImageFromEntity:entity placeholderImage:placeholderImage];
    
    XCTAssertNil(_imageView.hnk_requestedCacheKey, @"");
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(image, result, @"");
}

- (void)testSetImageFromEntityImage_ImageSet_NilPlaceholder_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _imageView.image = previousImage;
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:key image:image];
    
    [_imageView hnk_setImageFromEntity:entity placeholderImage:nil];
    
    XCTAssertEqualObjects(_imageView.hnk_requestedCacheKey, key,  @"");
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, previousImage, @"");
}

#pragma mark setImageFromURL:

- (void)testSetImageFromURL_MemoryCacheMiss
{
    NSURL *url = [NSURL URLWithString:@"http://imgs.xkcd.com/comics/election.png"];
    
    [_imageView hnk_setImageFromURL:url];
    
    XCTAssertEqualObjects(_imageView.hnk_requestedCacheKey, url.absoluteString,  @"");
    XCTAssertNil(_imageView.image, @"");
}

- (void)testSetImageFromURL_ImageSet_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _imageView.image = previousImage;
    NSURL *url = [NSURL URLWithString:@"http://imgs.xkcd.com/comics/election.png"];

    [_imageView hnk_setImageFromURL:url];
    
    XCTAssertEqualObjects(_imageView.hnk_requestedCacheKey, url.absoluteString,  @"");
    XCTAssertEqualObjects(_imageView.image, previousImage, @"");
}

- (void)testSetImageFromURL_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = @"http://imgs.xkcd.com/comics/election.png";
    HNKCacheFormat *format = _imageView.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    NSURL *url = [NSURL URLWithString:key];
    
    [_imageView hnk_setImageFromURL:url];
    
    XCTAssertNil(_imageView.hnk_requestedCacheKey, @"");
    XCTAssertNil(_imageView.hnk_entity, @"");
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(image, result, @"");
}

- (void)testSetImageFromURLPlaceholderImage_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    UIImage *placeholderImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = @"http://imgs.xkcd.com/comics/election.png";
    HNKCacheFormat *format = _imageView.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    NSURL *url = [NSURL URLWithString:key];
    
    [_imageView hnk_setImageFromURL:url placeholderImage:placeholderImage];
    
    XCTAssertNil(_imageView.hnk_requestedCacheKey, @"");
    XCTAssertNil(_imageView.hnk_entity, @"");
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, image, @"");
}

- (void)testSetImageFromURLPlaceholderImage_MemoryCacheMiss
{
    UIImage *placeholderImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = @"http://imgs.xkcd.com/comics/election.png";
    NSURL *url = [NSURL URLWithString:key];
    
    [_imageView hnk_setImageFromURL:url placeholderImage:placeholderImage];
    
    XCTAssertEqualObjects(_imageView.hnk_requestedCacheKey, url.absoluteString,  @"");
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, placeholderImage, @"");
}

- (void)testSetImageFromURLPlaceholderImage_ImageSet_NilPlaceholder_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _imageView.image = previousImage;
    NSString *key = @"http://imgs.xkcd.com/comics/election.png";
    NSURL *url = [NSURL URLWithString:key];
    
    [_imageView hnk_setImageFromURL:url placeholderImage:nil];
    
    XCTAssertEqualObjects(_imageView.hnk_requestedCacheKey, url.absoluteString,  @"");
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, previousImage, @"");
}

- (void)testSetImageFromURLSuccessFailure_MemoryCacheMiss
{
    NSURL *url = [NSURL URLWithString:@"http://imgs.xkcd.com/comics/election.png"];
    
    [_imageView hnk_setImageFromURL:url success:nil failure:nil];
    
    XCTAssertEqualObjects(_imageView.hnk_requestedCacheKey, url.absoluteString,  @"");
    XCTAssertNil(_imageView.image, @"");
}

- (void)testSetImageFromURLSuccessFailure_ImageSet_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _imageView.image = previousImage;
    NSURL *url = [NSURL URLWithString:@"http://imgs.xkcd.com/comics/election.png"];
    
    [_imageView hnk_setImageFromURL:url success:nil failure:nil];
    
    XCTAssertEqualObjects(_imageView.hnk_requestedCacheKey, url.absoluteString,  @"");
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, previousImage, @"");
}

- (void)testSetImageFromURLSuccessFailure_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = @"http://imgs.xkcd.com/comics/election.png";
    HNKCacheFormat *format = _imageView.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    NSURL *url = [NSURL URLWithString:key];
    
    [_imageView hnk_setImageFromURL:url success:^(UIImage *result) {
        XCTAssertEqualObjects(result, image, @"");
    } failure:^(NSError *error) {
        XCTFail(@"");
    }];
    
    XCTAssertNil(_imageView.hnk_requestedCacheKey, @"");
    XCTAssertNil(_imageView.hnk_entity, @"");
    XCTAssertNil(_imageView.image, @"");
}

- (void)testSetImageFromURLSuccessFailure_SuccesNil_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = @"http://imgs.xkcd.com/comics/election.png";
    HNKCacheFormat *format = _imageView.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    NSURL *url = [NSURL URLWithString:key];
    
    [_imageView hnk_setImageFromURL:url success:nil failure:^(NSError *error) {
        XCTFail(@"");
    }];
    
    XCTAssertNil(_imageView.hnk_requestedCacheKey, @"");
    XCTAssertNil(_imageView.hnk_entity, @"");
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, image, @"");
}

- (void)testSetImageFromURLSuccessFailure_DownloadSuccess
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
         [_imageView hnk_setImageFromURL:URL success:^(UIImage *image) {
             dispatch_semaphore_signal(semaphore);
         } failure:^(NSError *error) {
             XCTFail(@"");
             dispatch_semaphore_signal(semaphore);
         }];
     }];
}

- (void)testSetImageFromURLSuccessFailure_DownloadFailure
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
         [_imageView hnk_setImageFromURL:URL success:^(UIImage *image) {
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
        NSString *contentLengthString = [NSString stringWithFormat:@"%lu", data.length * 10];
        OHHTTPStubsResponse *response = [OHHTTPStubsResponse responseWithData:data statusCode:200 headers:nil];
        response.httpHeaders = @{@"Content-Length": contentLengthString}; // See: https://github.com/AliSoftware/OHHTTPStubs/pull/62
        return response;
    }];
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore)
     {
         [_imageView hnk_setImageFromURL:URL success:^(UIImage *image) {
             XCTFail(@"");
             dispatch_semaphore_signal(semaphore);
         } failure:^(NSError *error) {
             dispatch_semaphore_signal(semaphore);
             XCTAssertNotNil(error, @"");
             XCTAssertEqual(HNKErrorImageFromURLMissingData, error.code, @"");
         }];
     }];
}

#pragma mark cancelImageRequest

- (void)testCancelImageRequest_NoRequest
{
    [_imageView hnk_cancelImageRequest];

    XCTAssertNil(_imageView.hnk_requestedCacheKey, @"");
    XCTAssertNil(_imageView.hnk_entity, @"");
}

- (void)testCancelImageRequest_AfterRequest
{
    NSURL *url = [NSURL URLWithString:@"http://imgs.xkcd.com/comics/election.png"];
    [_imageView hnk_setImageFromURL:url];
    
    [_imageView hnk_cancelImageRequest];

    XCTAssertNil(_imageView.hnk_requestedCacheKey, @"");
    XCTAssertNil(_imageView.hnk_entity, @"");

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
