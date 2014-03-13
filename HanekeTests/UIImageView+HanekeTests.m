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

@interface UIImageView_HanekeTests : XCTestCase

@end

@implementation UIImageView_HanekeTests {
    UIImageView *_imageView;
}

- (void)setUp
{
    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
}

- (void)tearDown
{
    HNKCacheFormat *format = _imageView.hnk_cacheFormat;
    [[HNKCache sharedCache] clearFormatNamed:format.name];
}

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

- (void)testSetImageWithKey_MemoryCacheMiss
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];

    [_imageView hnk_setImage:image withKey:key];
    
    XCTAssertNil(_imageView.image, @"");
}

- (void)testSetImageWithKey_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    HNKCacheFormat *format = _imageView.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_imageView hnk_setImage:image withKey:key];
    
    XCTAssertEqualObjects(_imageView.image, image, @"");
}

- (void)testSetImageWithKeyPlaceholderImage_MemoryCacheMiss
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    UIImage *placeholderImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    
    [_imageView hnk_setImage:image withKey:key placeholderImage:placeholderImage];
    
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
    
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(image, result, @"");
}

- (void)testSetImageFromFile_MemoryCacheMiss
{
    NSString *path = [self fixturePathWithName:@"image.png"];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    [UIImagePNGRepresentation(image) writeToFile:path atomically:YES];

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
    
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, image, @"");
}

- (void)testSetImageFromFilePlaceholderImage_MemoryCacheMiss
{
    UIImage *placeholderImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = [self fixturePathWithName:@"image.png"];

    [_imageView hnk_setImageFromFile:key placeholderImage:placeholderImage];
    
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, placeholderImage, @"");
}

- (void)testSetImageFromFilePlaceholderImage_ImageSet_NilPlaceholder_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _imageView.image = previousImage;
    NSString *key = [self fixturePathWithName:@"image.png"];
    
    [_imageView hnk_setImageFromFile:key placeholderImage:nil];
    
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
    
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, image, @"");
}

- (void)testSetImageFromFileSuccessFailure_MemoryCacheMiss
{
    NSString *key = [self fixturePathWithName:@"image.png"];
    
    [_imageView hnk_setImageFromFile:key success:nil failure:nil];
    
    XCTAssertNil(_imageView.image, @"");
}

- (void)testSetImageFromFileSuccessFailure_ImageSet_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _imageView.image = previousImage;
    NSString *key = [self fixturePathWithName:@"image.png"];
    
    [_imageView hnk_setImageFromFile:key success:nil failure:nil];
    
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, previousImage, @"");
}

- (void)testSetImageFromFileSuccessFailure_NoSuchFileError
{
    NSString *key = [self fixturePathWithName:@"image.png"];
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_imageView hnk_setImageFromFile:key success:^(UIImage *result) {
            XCTFail(@"");
        } failure:^(NSError *error) {
            XCTAssertNotNil(error);
            XCTAssertEqual(error.code, NSFileReadNoSuchFileError, @"");
            dispatch_semaphore_signal(semaphore);
        }];
    }];
}

- (void)testSetImageFromFileSuccessFailure_CannotReadImageFromData
{
    NSString *path = [self fixturePathWithName:@"image.png"];
    NSData *data = [NSData data];
    [data writeToFile:path atomically:YES];
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_imageView hnk_setImageFromFile:path success:^(UIImage *result) {
            XCTFail(@"");
         } failure:^(NSError *error) {
            XCTAssertNotNil(error);
            XCTAssertEqualObjects(error.domain, HNKErrorDomain, @"");
            XCTAssertEqual(error.code, HNKErrorEntityCannotReadImageFromData, @"");
            dispatch_semaphore_signal(semaphore);
        }];
    }];
    
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

- (void)testSetImageFromEntity_MemoryCacheMiss
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:@"test" data:nil image:image];
    [_imageView hnk_setImageFromEntity:entity];
    XCTAssertNil(_imageView.image, @"");
}

- (void)testSetImageFromEntity_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = @"test";
    HNKCacheFormat *format = _imageView.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:key data:nil image:image];
    
    [_imageView hnk_setImageFromEntity:entity];
    
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(image, result, @"");
}

- (void)testSetImageFromEntityPlaceholderImage_MemoryCacheMiss
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    UIImage *placeholderImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:@"test" data:nil image:image];
    
    [_imageView hnk_setImageFromEntity:entity placeholderImage:placeholderImage];
    
    XCTAssertEqualObjects(_imageView.image, placeholderImage, @"");
}

- (void)testSetImageFromEntityPlaceholderImage_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    UIImage *placeholderImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = @"test";
    HNKCacheFormat *format = _imageView.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:key data:nil image:image];
    
    [_imageView hnk_setImageFromEntity:entity placeholderImage:placeholderImage];
    
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(image, result, @"");
}

- (void)testSetImageFromURL_MemoryCacheMiss
{
    NSURL *url = [NSURL URLWithString:@"http://imgs.xkcd.com/comics/election.png"];
    
    [_imageView hnk_setImageFromURL:url];
    
    XCTAssertNil(_imageView.image, @"");
}

- (void)testSetImageFromURL_ImageSet_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _imageView.image = previousImage;
    NSURL *url = [NSURL URLWithString:@"http://imgs.xkcd.com/comics/election.png"];

    [_imageView hnk_setImageFromURL:url];
    
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
    
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, image, @"");
}

- (void)testSetImageFromURLPlaceholderImage_MemoryCacheMiss
{
    UIImage *placeholderImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    NSString *key = @"http://imgs.xkcd.com/comics/election.png";
    NSURL *url = [NSURL URLWithString:key];
    
    [_imageView hnk_setImageFromURL:url placeholderImage:placeholderImage];
    
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
    
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, previousImage, @"");
}

- (void)testSetImageFromURLSuccessFailure_MemoryCacheMiss
{
    NSURL *url = [NSURL URLWithString:@"http://imgs.xkcd.com/comics/election.png"];
    
    [_imageView hnk_setImageFromURL:url success:nil failure:nil];
    
    XCTAssertNil(_imageView.image, @"");
}

- (void)testSetImageFromURLSuccessFailure_ImageSet_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _imageView.image = previousImage;
    NSURL *url = [NSURL URLWithString:@"http://imgs.xkcd.com/comics/election.png"];
    
    [_imageView hnk_setImageFromURL:url success:nil failure:nil];
    
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
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, image, @"");
}

- (void)testCancelImageRequest_NoRequest
{
    [_imageView hnk_cancelImageRequest];
}

- (void)testCancelImageRequest_AfterRequest
{
    NSURL *url = [NSURL URLWithString:@"http://imgs.xkcd.com/comics/election.png"];
    [_imageView hnk_setImageFromURL:url];
    
    [_imageView hnk_cancelImageRequest];
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
