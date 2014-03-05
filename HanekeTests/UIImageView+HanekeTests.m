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

- (void)testSetImageFromFile
{
    NSString *directory = NSHomeDirectory();
    NSString *path = [directory stringByAppendingPathComponent:@"HanekeTests"];
    path = [directory stringByAppendingPathComponent:@"fixtures"];
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    path = [directory stringByAppendingPathComponent:@"image.png"];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    [UIImagePNGRepresentation(image) writeToFile:path atomically:YES];

    [_imageView hnk_setImageFromFile:path];
    
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

- (void)testSetImageFromEntity
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    id<HNKCacheEntity> entity = [HNKCache entityWithKey:@"test" data:nil image:image];
    [_imageView hnk_setImageFromEntity:entity];
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

@end
