//
//  UIView+HanekeTests.m
//  Haneke
//
//  Created by Hermes Pique on 8/20/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UIView+Haneke.h"

@interface UIView_HanekeTests : XCTestCase

@end

@implementation UIView_HanekeTests {
    UIView *_sut;
}

- (void)setUp
{
    [super setUp];
    _sut = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
}

- (void)testScaleMode_UIViewContentModeScaleToFill
{
    _sut.contentMode = UIViewContentModeScaleToFill;
    XCTAssertEqual(_sut.hnk_scaleMode, HNKScaleModeFill);
}

- (void)testScaleMode_UIViewContentModeScaleAspectFit
{
    _sut.contentMode = UIViewContentModeScaleAspectFit;
    XCTAssertEqual(_sut.hnk_scaleMode, HNKScaleModeAspectFit);
}

- (void)testScaleMode_UIViewContentModeScaleAspectFill
{
    _sut.contentMode = UIViewContentModeScaleAspectFill;
    XCTAssertEqual(_sut.hnk_scaleMode, HNKScaleModeAspectFill);
}

- (void)testScaleMode_UIViewContentModeRedraw
{
    _sut.contentMode = UIViewContentModeRedraw;
    XCTAssertEqual(_sut.hnk_scaleMode, HNKScaleModeNone);
}

- (void)testScaleMode_UIViewContentModeCenter
{
    _sut.contentMode = UIViewContentModeCenter;
    XCTAssertEqual(_sut.hnk_scaleMode, HNKScaleModeNone);
}

- (void)testScaleMode_UIViewContentModeTop
{
    _sut.contentMode = UIViewContentModeTop;
    XCTAssertEqual(_sut.hnk_scaleMode, HNKScaleModeNone);
}

- (void)testScaleMode_UIViewContentModeBottom
{
    _sut.contentMode = UIViewContentModeBottom;
    XCTAssertEqual(_sut.hnk_scaleMode, HNKScaleModeNone);
}

- (void)testScaleMode_UIViewContentModeLeft
{
    _sut.contentMode = UIViewContentModeLeft;
    XCTAssertEqual(_sut.hnk_scaleMode, HNKScaleModeNone);
}

- (void)testScaleMode_UIViewContentModeRight
{
    _sut.contentMode = UIViewContentModeRight;
    XCTAssertEqual(_sut.hnk_scaleMode, HNKScaleModeNone);
}

- (void)testScaleMode_UIViewContentModeTopLeft
{
    _sut.contentMode = UIViewContentModeTopLeft;
    XCTAssertEqual(_sut.hnk_scaleMode, HNKScaleModeNone);
}

- (void)testScaleMode_UIViewContentModeTopRight
{
    _sut.contentMode = UIViewContentModeTopRight;
    XCTAssertEqual(_sut.hnk_scaleMode, HNKScaleModeNone);
}

- (void)testScaleMode_UIViewContentModeBottomLeft
{
    _sut.contentMode = UIViewContentModeBottomLeft;
    XCTAssertEqual(_sut.hnk_scaleMode, HNKScaleModeNone);
}

- (void)testScaleMode_UIViewContentModeBottomRight
{
    _sut.contentMode = UIViewContentModeBottomRight;
    XCTAssertEqual(_sut.hnk_scaleMode, HNKScaleModeNone);
}

- (void)testSharedFormatWithSize
{
    const CGSize size = CGSizeMake(10, 20);
    const HNKScaleMode scaleMode = HNKScaleModeFill;
    
    HNKCacheFormat *result = [HNKCache sharedFormatWithSize:size scaleMode:scaleMode];
    
    XCTAssertEqual(result.allowUpscaling, YES, @"");
    XCTAssertTrue(result.compressionQuality == 0.75, @"");
    XCTAssertTrue(result.diskCapacity == 10 * 1024 * 1024, @"");
    XCTAssertEqual(result.scaleMode, scaleMode, @"");
    XCTAssertTrue(CGSizeEqualToSize(result.size, size), @"");
    XCTAssertNotNil([HNKCache sharedCache].formats[result.name], @"");
}

- (void)testSharedFormatWithSize_HNKScaleModeAspectFit
{
    const HNKScaleMode scaleMode = HNKScaleModeAspectFit;
    
    HNKCacheFormat *result = [HNKCache sharedFormatWithSize:CGSizeMake(10, 20) scaleMode:scaleMode];
    
    XCTAssertEqual(result.scaleMode, scaleMode, @"");
}

- (void)testSharedFormatWithSize_HNKScaleModeAspectFill
{
    const HNKScaleMode scaleMode = HNKScaleModeAspectFill;
    
    HNKCacheFormat *result = [HNKCache sharedFormatWithSize:CGSizeMake(10, 20) scaleMode:scaleMode];
    
    XCTAssertEqual(result.scaleMode, scaleMode, @"");
}

- (void)testSharedFormatWithSize_HNKScaleModeNone
{
    const HNKScaleMode scaleMode = HNKScaleModeNone;
    
    HNKCacheFormat *result = [HNKCache sharedFormatWithSize:CGSizeMake(10, 20) scaleMode:scaleMode];
    
    XCTAssertEqual(result.scaleMode, scaleMode, @"");
}

- (void)testSharedFormatWithSize_Twice
{
    const CGSize size = CGSizeMake(10, 20);
    const HNKScaleMode scaleMode = HNKScaleModeAspectFit;
    HNKCacheFormat *format = [HNKCache sharedFormatWithSize:size scaleMode:scaleMode];

    HNKCacheFormat *result = [HNKCache sharedFormatWithSize:size scaleMode:scaleMode];

    XCTAssertEqualObjects(result, format, @"");
}

- (void)testRegisterFormat
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:self.name];
    
    [HNKCache registerSharedFormat:format];
    
    XCTAssertEqualObjects([HNKCache sharedCache].formats[format.name], format, @"");
}

- (void)testRegisterFormat_Twice
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:self.name];
    
    [HNKCache registerSharedFormat:format];
    [HNKCache registerSharedFormat:format];
    
    XCTAssertEqualObjects([HNKCache sharedCache].formats[format.name], format, @"");
}

@end
