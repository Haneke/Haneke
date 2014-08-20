//
//  UIButton+HanekeTests.m
//  Haneke
//
//  Created by Hermes Pique on 8/20/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UIView+Haneke.h"
#import "UIButton+Haneke.h"
#import "UIImage+HanekeTestUtils.h"
#import "XCTestCase+HanekeTestUtils.h"
#import <OHHTTPStubs/OHHTTPStubs.h>

@interface UIButton()

@property (nonatomic, readonly) id<HNKCacheEntity> hnk_imageEntity;
@property (nonatomic, readonly) id<HNKCacheEntity> hnk_backgroundImageEntity;

@end

@interface UIButton_HanekeTests : XCTestCase

@end

@implementation UIButton_HanekeTests {
    UIButton *_sut;
}

- (void)setUp
{
    [super setUp];
    _sut = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
}

- (void)tearDown
{
    [_sut hnk_cancelSetImage];
    [_sut hnk_cancelSetBackgroundImage];
    [OHHTTPStubs removeAllStubs];
    
    HNKCacheFormat *imageFormat = _sut.hnk_imageFormat;
    [[HNKCache sharedCache] removeImagesOfFormatNamed:imageFormat.name];

    HNKCacheFormat *backgroundImageFormat = _sut.hnk_backgroundImageFormat;
    [[HNKCache sharedCache] removeImagesOfFormatNamed:backgroundImageFormat.name];
    
    [super tearDown];
}

#pragma mark imageFormat

- (void)testImageFormat
{
    const CGRect contentRect = [_sut contentRectForBounds:_sut.bounds];
    const CGRect imageRect = [_sut imageRectForContentRect:contentRect];

    HNKCacheFormat *result = _sut.hnk_imageFormat;
    
    XCTAssertEqual(result.allowUpscaling, YES, @"");
    XCTAssertTrue(result.compressionQuality == 0.75, @"");
    XCTAssertTrue(result.diskCapacity == 10 * 1024 * 1024, @"");
    XCTAssertEqual(result.scaleMode, _sut.hnk_scaleMode, @"");
    XCTAssertTrue(CGSizeEqualToSize(result.size, imageRect.size), @"");
    
}

// TODO

#pragma mark setImageWithKey

- (void)testSetImageWithKey_MemoryCacheHit_UIControlStateNormal
{
    [self _testSetImageWithKey_MemoryCacheHit_state:UIControlStateNormal];
}

- (void)testSetImageWithKey_MemoryCacheHit_UIControlStateHighlighted
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 20)];
    [_sut setImage:image forState:UIControlStateNormal];
    
    [self _testSetImageWithKey_MemoryCacheHit_state:UIControlStateHighlighted];
}

- (void)testSetImageWithKey_MemoryCacheHit_UIControlStateDisabled
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 20)];
    [_sut setImage:image forState:UIControlStateNormal];
    
    [self _testSetImageWithKey_MemoryCacheHit_state:UIControlStateDisabled];
}

- (void)testSetImageWithKey_MemoryCacheHit_UIControlStateSelected
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 20)];
    [_sut setImage:image forState:UIControlStateNormal];
    
    [self _testSetImageWithKey_MemoryCacheHit_state:UIControlStateSelected];
}

- (void)testSetImageWithKey_MemoryCacheMiss
{
    NSString *key = self.name;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    
    [_sut hnk_setImage:image withKey:key forState:UIControlStateNormal];
    
    XCTAssertEqualObjects(_sut.hnk_imageEntity.cacheKey, key,  @"");
    XCTAssertNil([_sut imageForState:UIControlStateNormal], @"");
}

- (void)testSetImageWithKeyplaceholder_MemoryCacheMiss
{
    NSString *key = self.name;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 20)];
    UIImage *placeholder = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    
    [_sut hnk_setImage:image withKey:key forState:UIControlStateNormal placeholder:placeholder];
    
    XCTAssertEqualObjects(_sut.hnk_imageEntity.cacheKey, key,  @"");
    XCTAssertEqualObjects([_sut imageForState:UIControlStateNormal], placeholder, @"");
}

#pragma mark setBackgroundImageWithKey

- (void)testSetBackgroundImageWithKey_MemoryCacheHit_UIControlStateNormal
{
    [self _testSetBackgroundImageWithKey_MemoryCacheHit_state:UIControlStateNormal];
}

- (void)testSetBackgroundImageWithKey_MemoryCacheHit_UIControlStateHighlighted
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 20)];
    [_sut setBackgroundImage:image forState:UIControlStateNormal];
    
    [self _testSetBackgroundImageWithKey_MemoryCacheHit_state:UIControlStateHighlighted];
}

- (void)testSetBackgroundImageWithKey_MemoryCacheHit_UIControlStateDisabled
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 20)];
    [_sut setBackgroundImage:image forState:UIControlStateNormal];
    
    [self _testSetBackgroundImageWithKey_MemoryCacheHit_state:UIControlStateDisabled];
}

- (void)testSetBackgroundImageWithKey_MemoryCacheHit_UIControlStateSelected
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 20)];
    [_sut setBackgroundImage:image forState:UIControlStateNormal];
    
    [self _testSetBackgroundImageWithKey_MemoryCacheHit_state:UIControlStateSelected];
}

#pragma mark Helpers

- (void)_testSetImageWithKey_MemoryCacheHit_state:(UIControlState)state
{
    NSString *key = self.name;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    
    HNKCacheFormat *format = _sut.hnk_imageFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_sut hnk_setImage:image withKey:key forState:state];
    
    XCTAssertNil(_sut.hnk_imageEntity,  @"");
    XCTAssertEqualObjects([_sut imageForState:state], image, @"");
}

- (void)_testSetBackgroundImageWithKey_MemoryCacheHit_state:(UIControlState)state
{
    NSString *key = self.name;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    
    HNKCacheFormat *format = _sut.hnk_backgroundImageFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_sut hnk_setBackgroundImage:image withKey:key forState:state];
    
    XCTAssertNil(_sut.hnk_backgroundImageEntity,  @"");
    XCTAssertEqualObjects([_sut backgroundImageForState:state], image, @"");
}


@end
