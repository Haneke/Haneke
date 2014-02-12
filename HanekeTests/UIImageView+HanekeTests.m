//
//  UIImageView+HanekeTests.m
//  Haneke
//
//  Created by Hermes on 12/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UIImageView+Haneke.h"

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

@end
