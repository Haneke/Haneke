//
//  UIImageView+HanekeTests.m
//  Haneke
//
//  Created by Hermes on 12/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UIImageView+Haneke.h"
#import "UIImage+HanekeTestUtils.h"
#import "HNKCache+HanekeTestUtils.h"

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
    XCTAssertEqual(result.size, _imageView.bounds.size, @"");
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

- (void)testSetImageWithKey
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    [_imageView hnk_setImage:image withKey:@"test"];
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

- (void)testSetImageFromFile_MemoryCacheMiss_ImageSet
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

- (void)testSetImageFromFilePlaceholderImage_NilPlaceholder_MemoryCacheMiss_ImageSet
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _imageView.image = previousImage;
    NSString *key = [self fixturePathWithName:@"image.png"];
    
    [_imageView hnk_setImageFromFile:key placeholderImage:nil];
    
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, previousImage, @"");
}

- (void)testSetImageFromFileFailure_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    NSString *key = [self fixturePathWithName:@"image.png"];
    HNKCacheFormat *format = _imageView.hnk_cacheFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_imageView hnk_setImageFromFile:key failure:^(NSError *error) {
        XCTFail(@"");
    }];
    
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(image, result, @"");
}

- (void)testSetImageFromFileFailure_MemoryCacheMiss
{
    NSString *key = [self fixturePathWithName:@"image.png"];
    
    [_imageView hnk_setImageFromFile:key failure:nil];
    
    XCTAssertNil(_imageView.image, @"");
}

- (void)testSetImageFromFileFailure_MemoryCacheMiss_ImageSet
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    _imageView.image = previousImage;
    NSString *key = [self fixturePathWithName:@"image.png"];
    
    [_imageView hnk_setImageFromFile:key failure:nil];
    
    UIImage *result = _imageView.image;
    XCTAssertEqualObjects(result, previousImage, @"");
}

- (void)testSetImageFromEntity
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:@"test" data:nil image:image];
    [_imageView hnk_setImageFromEntity:entity];
}

- (void)testSetImageFromEntity_Existing
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

- (void)testSetImageFromURL
{
    NSURL *url = [NSURL URLWithString:@"http://imgs.xkcd.com/comics/election.png"];
    [_imageView hnk_setImageFromURL:url];
}

- (void)testSetImageFromURL_Existing
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
