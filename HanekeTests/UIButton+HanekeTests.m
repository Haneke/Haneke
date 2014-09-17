//
//  UIButton+HanekeTests.m
//  Haneke
//
//  Created by Hermes Pique on 8/20/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HNKDiskFetcher.h"
#import "HNKNetworkFetcher.h"
#import "HNKSimpleFetcher.h"
#import "UIView+Haneke.h"
#import "UIButton+Haneke.h"
#import "UIImage+HanekeTestUtils.h"
#import "XCTestCase+HanekeTestUtils.h"
#import <OHHTTPStubs/OHHTTPStubs.h>

@interface UIButton()

@property (nonatomic, readonly) id<HNKFetcher> hnk_imageFetcher;
@property (nonatomic, readonly) id<HNKFetcher> hnk_backgroundImageFetcher;

@end

@interface UIButton_HanekeTests : XCTestCase

@end

@implementation UIButton_HanekeTests {
    UIButton *_sut;
    NSString *_directory;
}

- (void)setUp
{
    [super setUp];
    _sut = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
    
    _directory = NSHomeDirectory();
    _directory = [_directory stringByAppendingPathComponent:@"io.haneke"];
    _directory = [_directory stringByAppendingPathComponent:NSStringFromClass(self.class)];
    [[NSFileManager defaultManager] createDirectoryAtPath:_directory withIntermediateDirectories:YES attributes:nil error:nil];
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
    
    NSString *directory = NSHomeDirectory();
    directory = [directory stringByAppendingPathComponent:@"io.haneke"];
    [[NSFileManager defaultManager] removeItemAtPath:directory error:nil];
    
    [super tearDown];
}

#pragma mark imageFormat

- (void)testImageFormat_HNKScaleModeAspectFit
{
    const CGRect contentRect = [_sut contentRectForBounds:_sut.bounds];
    const CGSize formatSize = contentRect.size;

    HNKCacheFormat *result = _sut.hnk_imageFormat;
    
    XCTAssertEqual(result.allowUpscaling, NO, @"");
    XCTAssertTrue(result.compressionQuality == HNKViewFormatCompressionQuality, @"");
    XCTAssertTrue(result.diskCapacity == HNKViewFormatDiskCapacity, @"");
    XCTAssertEqual(result.scaleMode, HNKScaleModeAspectFit, @"");
    XCTAssertTrue(CGSizeEqualToSize(result.size, formatSize), @"");
}

- (void)testImageFormat_HNKScaleModeAspectFit_UIControlContentHorizontalAlignmentFill
{
    const CGRect contentRect = [_sut contentRectForBounds:_sut.bounds];
    const CGSize formatSize = contentRect.size;
    _sut.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    
    HNKCacheFormat *result = _sut.hnk_imageFormat;
    
    XCTAssertEqual(result.allowUpscaling, NO, @"");
    XCTAssertTrue(result.compressionQuality == HNKViewFormatCompressionQuality, @"");
    XCTAssertTrue(result.diskCapacity == HNKViewFormatDiskCapacity, @"");
    XCTAssertEqual(result.scaleMode, HNKScaleModeAspectFit, @"");
    XCTAssertTrue(CGSizeEqualToSize(result.size, formatSize), @"");
}

- (void)testImageFormat_HNKScaleModeAspectFit_imageEdgeInsets
{
    _sut.imageEdgeInsets = UIEdgeInsetsMake(1, 2, 3, 4);
    const CGRect contentRect = [_sut contentRectForBounds:_sut.bounds];
    const CGSize formatSize = CGSizeMake(contentRect.size.width - _sut.imageEdgeInsets.left - _sut.imageEdgeInsets.right,
                                         contentRect.size.height - _sut.imageEdgeInsets.top - _sut.imageEdgeInsets.bottom);
    
    HNKCacheFormat *result = _sut.hnk_imageFormat;
    
    XCTAssertEqual(result.allowUpscaling, NO, @"");
    XCTAssertTrue(result.compressionQuality == HNKViewFormatCompressionQuality, @"");
    XCTAssertTrue(result.diskCapacity == HNKViewFormatDiskCapacity, @"");
    XCTAssertEqual(result.scaleMode, HNKScaleModeAspectFit, @"");
    XCTAssertTrue(CGSizeEqualToSize(result.size, formatSize), @"");
}

- (void)testImageFormat_HNKScaleModeFill
{
    const CGRect contentRect = [_sut contentRectForBounds:_sut.bounds];
    const CGSize formatSize = contentRect.size;
    _sut.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    _sut.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    
    HNKCacheFormat *result = _sut.hnk_imageFormat;
    
    XCTAssertEqual(result.allowUpscaling, YES, @"");
    XCTAssertTrue(result.compressionQuality == HNKViewFormatCompressionQuality, @"");
    XCTAssertTrue(result.diskCapacity == HNKViewFormatDiskCapacity, @"");
    XCTAssertEqual(result.scaleMode, HNKScaleModeFill, @"");
    XCTAssertTrue(CGSizeEqualToSize(result.size, formatSize), @"");
}

- (void)testImageFormat_HNKScaleModeFill_imageEdgeInsets
{
    _sut.imageEdgeInsets = UIEdgeInsetsMake(1, 2, 3, 4);
    const CGRect contentRect = [_sut contentRectForBounds:_sut.bounds];
    const CGSize formatSize = CGSizeMake(contentRect.size.width - _sut.imageEdgeInsets.left - _sut.imageEdgeInsets.right,
                                         contentRect.size.height - _sut.imageEdgeInsets.top - _sut.imageEdgeInsets.bottom);
    _sut.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    _sut.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    
    HNKCacheFormat *result = _sut.hnk_imageFormat;
    
    XCTAssertEqual(result.allowUpscaling, YES, @"");
    XCTAssertTrue(result.compressionQuality == HNKViewFormatCompressionQuality, @"");
    XCTAssertTrue(result.diskCapacity == HNKViewFormatDiskCapacity, @"");
    XCTAssertEqual(result.scaleMode, HNKScaleModeFill, @"");
    XCTAssertTrue(CGSizeEqualToSize(result.size, formatSize), @"");
}

#pragma mark setImageFormat

- (void)testSetImageFormat_Nil
{
    _sut.hnk_imageFormat = nil;
    XCTAssertNotNil(_sut.hnk_imageFormat, @"");
}

- (void)testSetImageFormat_NilAfterValue
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"test"];
    _sut.hnk_imageFormat = format;
    
    _sut.hnk_imageFormat = nil;
    HNKCacheFormat *result = _sut.hnk_imageFormat;
    XCTAssertNotNil(result, @"");
    XCTAssertNotEqualObjects(result, format, @"");
}

- (void)testSetImageFormat_Value
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"test"];
    _sut.hnk_imageFormat = format;
    
    HNKCacheFormat *result = _sut.hnk_imageFormat;
    XCTAssertEqualObjects(result, format, @"");
}

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
    
    XCTAssertEqualObjects(_sut.hnk_imageFetcher.cacheKey, key,  @"");
    XCTAssertNil([_sut imageForState:UIControlStateNormal], @"");
}

- (void)testSetImageWithKey_ImageSet_MemoryCacheMiss
{
    NSString *key = self.name;
    const UIControlState state = UIControlStateNormal;
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    [_sut setImage:previousImage forState:state];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 20)];
    
    [_sut hnk_setImage:image withKey:key forState:state];
    
    XCTAssertEqualObjects(_sut.hnk_imageFetcher.cacheKey, key,  @"");
    XCTAssertEqualObjects([_sut imageForState:state], previousImage, @"");
}

- (void)testSetImageWithKeyPlaceholder_MemoryCacheHit
{
    NSString *key = self.name;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    UIImage *placeholder = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 20)];
    HNKCacheFormat *format = _sut.hnk_imageFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];

    [_sut hnk_setImage:image withKey:key forState:UIControlStateNormal placeholder:placeholder];
    
    XCTAssertNil(_sut.hnk_imageFetcher,  @"");
    XCTAssertEqualObjects([_sut imageForState:UIControlStateNormal], image, @"");
}

- (void)testSetImageWithKeyPlaceholder_MemoryCacheMiss
{
    NSString *key = self.name;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 20)];
    UIImage *placeholder = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    
    [_sut hnk_setImage:image withKey:key forState:UIControlStateNormal placeholder:placeholder];
    
    XCTAssertEqualObjects(_sut.hnk_imageFetcher.cacheKey, key,  @"");
    XCTAssertEqualObjects([_sut imageForState:UIControlStateNormal], placeholder, @"");
}

- (void)testSetImageWithKeyPlaceholder_ImageSet_MemoryCacheMiss
{
    NSString *key = self.name;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 20)];
    UIImage *placeholder = [UIImage hnk_imageWithColor:[UIColor yellowColor] size:CGSizeMake(10, 20)];
    const UIControlState state = UIControlStateNormal;
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    [_sut setImage:previousImage forState:state];
    
    [_sut hnk_setImage:image withKey:key forState:state placeholder:placeholder];
    
    XCTAssertEqualObjects(_sut.hnk_imageFetcher.cacheKey, key,  @"");
    XCTAssertEqualObjects([_sut imageForState:state], placeholder, @"");
}

- (void)testSetImageWithKeyPlaceholderSuccessFailure_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    HNKCacheFormat *format = _sut.hnk_imageFormat;
    NSString *key = self.name;
    const UIControlState state = UIControlStateNormal;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    __block BOOL success = NO;
    [_sut hnk_setImage:image withKey:key forState:state placeholder:nil success:^(UIImage *result) {
        XCTAssertEqualObjects(result, image, @"");
        success = YES;
    } failure:^(NSError *error) {
        XCTFail(@"");
    }];
    
    XCTAssertTrue(success, @"");
    XCTAssertNil(_sut.hnk_imageFetcher, @"");
    XCTAssertNil([_sut imageForState:state], @"");
}

- (void)testSetImageWithKeyPlaceholderSuccessFailure_SuccessNil_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    NSString *key = self.name;
    HNKCacheFormat *format = _sut.hnk_imageFormat;
    const UIControlState state = UIControlStateNormal;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_sut hnk_setImage:image withKey:key forState:state placeholder:nil success:nil failure:^(NSError *error) {
        XCTFail(@"");
    }];
    
    XCTAssertNil(_sut.hnk_imageFetcher, @"");
    XCTAssertEqualObjects([_sut imageForState:state], image, @"");
}

- (void)testSetImageWithKeyPlaceholderSuccessFailure_MemoryCacheMiss
{
    NSString *key = self.name;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    const UIControlState state = UIControlStateNormal;

    [_sut hnk_setImage:image withKey:key forState:state placeholder:nil success:nil failure:nil];
    
    XCTAssertEqualObjects(_sut.hnk_imageFetcher.cacheKey, key,  @"");
    XCTAssertNil([_sut imageForState:state], @"");
}

- (void)testSetImageWithKeyPlaceholderSuccessFailure_ImageSet_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    const UIControlState state = UIControlStateNormal;
    [_sut setImage:previousImage forState:state];
    NSString *key = self.name;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    
    [_sut hnk_setImage:image withKey:key forState:state placeholder:nil success:nil failure:nil];
    
    XCTAssertEqualObjects(_sut.hnk_imageFetcher.cacheKey, key,  @"");
    XCTAssertEqualObjects([_sut imageForState:state], previousImage, @"");
}

#pragma mark setImageFromFile

- (void)testSetImageFromFile_MemoryCacheHit_UIControlStateNormal
{
    NSString *path = [_directory stringByAppendingPathComponent:self.name];
    id<HNKFetcher> fetcher = [[HNKDiskFetcher alloc] initWithPath:path];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    HNKCacheFormat *format = _sut.hnk_imageFormat;
    [[HNKCache sharedCache] setImage:image forKey:fetcher.cacheKey formatName:format.name];
    const UIControlState state = UIControlStateNormal;
    
    [_sut hnk_setImageFromFile:path forState:state];
    
    XCTAssertNil(_sut.hnk_imageFetcher,  @"");
    XCTAssertEqualObjects([_sut imageForState:state], image, @"");
}

- (void)testSetImageFromFilePlaceholder_MemoryCacheMiss_UIControlStateSelected
{
    NSString *path = [_directory stringByAppendingPathComponent:self.name];
    id<HNKFetcher> fetcher = [[HNKDiskFetcher alloc] initWithPath:path];
    UIImage *placeholder = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    const UIControlState state = UIControlStateSelected;
    
    [_sut hnk_setImageFromFile:path forState:state placeholder:placeholder];
    
    XCTAssertEqualObjects(_sut.hnk_imageFetcher.cacheKey, fetcher.cacheKey,  @"");
    XCTAssertEqualObjects([_sut imageForState:state], placeholder, @"");
}

- (void)testSetImageFromFilePlaceholderSuccessFailure_MemoryCacheHit
{
    NSString *path = [_directory stringByAppendingPathComponent:self.name];
    id<HNKFetcher> fetcher = [[HNKDiskFetcher alloc] initWithPath:path];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    HNKCacheFormat *format = _sut.hnk_imageFormat;
    [[HNKCache sharedCache] setImage:image forKey:fetcher.cacheKey formatName:format.name];
    const UIControlState state = UIControlStateNormal;
    
    __block BOOL success = NO;
    [_sut hnk_setImageFromFile:path forState:state placeholder:nil success:^(UIImage *result) {
        XCTAssertEqualObjects(result, image, @"");
        success = YES;
    } failure:^(NSError *error) {
        XCTFail(@"");
    }];
    
    XCTAssertTrue(success, @"");
    XCTAssertNil(_sut.hnk_imageFetcher, @"");
    XCTAssertNil([_sut imageForState:state], @"");
}

#pragma mark setImageFromURL

- (void)testSetImageFromURL_MemoryCacheHit_UIControlStateNormal
{
    NSURL *URL = [NSURL URLWithString:@"http://haneke.io/image.jpg"];
    id<HNKFetcher> fetcher = [[HNKNetworkFetcher alloc] initWithURL:URL];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    HNKCacheFormat *format = _sut.hnk_imageFormat;
    [[HNKCache sharedCache] setImage:image forKey:fetcher.cacheKey formatName:format.name];
    const UIControlState state = UIControlStateNormal;
    
    [_sut hnk_setImageFromURL:URL forState:state];
    
    XCTAssertNil(_sut.hnk_imageFetcher,  @"");
    XCTAssertEqualObjects([_sut imageForState:state], image, @"");
}

- (void)testSetImageFromURLPlaceholder_MemoryCacheMiss_UIControlStateSelected
{
    NSURL *URL = [NSURL URLWithString:@"http://haneke.io/image.jpg"];
    id<HNKFetcher> fetcher = [[HNKNetworkFetcher alloc] initWithURL:URL];
    UIImage *placeholder = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    const UIControlState state = UIControlStateSelected;
    
    [_sut hnk_setImageFromURL:URL forState:state placeholder:placeholder];
    
    XCTAssertEqualObjects(_sut.hnk_imageFetcher.cacheKey, fetcher.cacheKey,  @"");
    XCTAssertEqualObjects([_sut imageForState:state], placeholder, @"");
}

- (void)testSetImageFromURLPlaceholderSuccessFailure_MemoryCacheHit
{
    NSURL *URL = [NSURL URLWithString:@"http://haneke.io/image.jpg"];
    id<HNKFetcher> fetcher = [[HNKNetworkFetcher alloc] initWithURL:URL];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    HNKCacheFormat *format = _sut.hnk_imageFormat;
    [[HNKCache sharedCache] setImage:image forKey:fetcher.cacheKey formatName:format.name];
    const UIControlState state = UIControlStateNormal;
    
    __block BOOL success = NO;
    [_sut hnk_setImageFromURL:URL forState:state placeholder:nil success:^(UIImage *result) {
        XCTAssertEqualObjects(result, image, @"");
        success = YES;
    } failure:^(NSError *error) {
        XCTFail(@"");
    }];
    
    XCTAssertTrue(success, @"");
    XCTAssertNil(_sut.hnk_imageFetcher, @"");
    XCTAssertNil([_sut imageForState:state], @"");
}

#pragma mark setImageFromFetcher

- (void)testSetImageFromFetcher_MemoryCacheHit_UIControlStateNormal
{
    id<HNKFetcher> fetcher = [[HNKSimpleFetcher alloc] initWithKey:self.name image:nil];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    HNKCacheFormat *format = _sut.hnk_imageFormat;
    [[HNKCache sharedCache] setImage:image forKey:fetcher.cacheKey formatName:format.name];
    const UIControlState state = UIControlStateNormal;
    
    [_sut hnk_setImageFromFetcher:fetcher forState:state];
    
    XCTAssertNil(_sut.hnk_imageFetcher,  @"");
    XCTAssertEqualObjects([_sut imageForState:state], image, @"");
}

- (void)testSetImageFromFetcherLPlaceholder_MemoryCacheMiss_UIControlStateSelected
{
    id<HNKFetcher> fetcher = [[HNKSimpleFetcher alloc] initWithKey:self.name image:nil];
    UIImage *placeholder = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    const UIControlState state = UIControlStateSelected;
    
    [_sut hnk_setImageFromFetcher:fetcher forState:state placeholder:placeholder];
    
    XCTAssertEqualObjects(_sut.hnk_imageFetcher, fetcher,  @"");
    XCTAssertEqualObjects([_sut imageForState:state], placeholder, @"");
}

- (void)testSetImageFromFetcherPlaceholderSuccessFailure_MemoryCacheHit
{
    id<HNKFetcher> fetcher = [[HNKSimpleFetcher alloc] initWithKey:self.name image:nil];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    HNKCacheFormat *format = _sut.hnk_imageFormat;
    [[HNKCache sharedCache] setImage:image forKey:fetcher.cacheKey formatName:format.name];
    const UIControlState state = UIControlStateNormal;
    
    __block BOOL success = NO;
    [_sut hnk_setImageFromFetcher:fetcher forState:state placeholder:nil success:^(UIImage *result) {
        XCTAssertEqualObjects(result, image, @"");
        success = YES;
    } failure:^(NSError *error) {
        XCTFail(@"");
    }];
    
    XCTAssertTrue(success, @"");
    XCTAssertNil(_sut.hnk_imageFetcher, @"");
    XCTAssertNil([_sut imageForState:state], @"");
}

#pragma mark cancelSetImage

- (void)testCancelSetImage_NoRequest
{
    [_sut hnk_cancelSetImage];
    
    XCTAssertNil(_sut.hnk_imageFetcher, @"");
}

- (void)testCancelSetImage_After
{
    NSURL *url = [NSURL URLWithString:@"http://imgs.xkcd.com/comics/election.png"];
    [_sut hnk_setImageFromURL:url forState:UIControlStateHighlighted placeholder:nil success:^(UIImage *image) {
        XCTFail(@"Unexpected success");
    } failure:^(NSError *error) {
        XCTFail(@"Unexpected success");
    }];
    
    [_sut hnk_cancelSetImage];
    
    XCTAssertNil(_sut.hnk_imageFetcher, @"");
    [self hnk_waitFor:0.1];
}

#pragma mark backgroundImageFormat

- (void)testBackgroundImageFormat
{
    const CGRect contentRect = [_sut contentRectForBounds:_sut.bounds];
    const CGSize formatSize = contentRect.size;
    
    HNKCacheFormat *result = _sut.hnk_backgroundImageFormat;
    
    XCTAssertEqual(result.allowUpscaling, YES, @"");
    XCTAssertTrue(result.compressionQuality == HNKViewFormatCompressionQuality, @"");
    XCTAssertTrue(result.diskCapacity == HNKViewFormatDiskCapacity, @"");
    XCTAssertEqual(result.scaleMode, HNKScaleModeFill, @"");
    XCTAssertTrue(CGSizeEqualToSize(result.size, formatSize), @"");
}

#pragma mark setBackgroundImageFormat

- (void)testSetBackgroundImageFormat_Nil
{
    _sut.hnk_backgroundImageFormat = nil;
    XCTAssertNotNil(_sut.hnk_backgroundImageFormat, @"");
}

- (void)testSetBackgroundImageFormat_NilAfterValue
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"test"];
    _sut.hnk_backgroundImageFormat = format;
    
    _sut.hnk_backgroundImageFormat = nil;
    HNKCacheFormat *result = _sut.hnk_backgroundImageFormat;
    XCTAssertNotNil(result, @"");
    XCTAssertNotEqualObjects(result, format, @"");
}

- (void)testSetBackgroundImageFormat_Value
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"test"];
    _sut.hnk_backgroundImageFormat = format;
    
    HNKCacheFormat *result = _sut.hnk_backgroundImageFormat;
    XCTAssertEqualObjects(result, format, @"");
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

- (void)testSetBackgroundImageWithKey_MemoryCacheMiss
{
    NSString *key = self.name;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    
    [_sut hnk_setBackgroundImage:image withKey:key forState:UIControlStateNormal];
    
    XCTAssertEqualObjects(_sut.hnk_backgroundImageFetcher.cacheKey, key,  @"");
    XCTAssertNil([_sut backgroundImageForState:UIControlStateNormal], @"");
}

- (void)testSetBackgroundImageWithKey_ImageSet_MemoryCacheMiss
{
    NSString *key = self.name;
    const UIControlState state = UIControlStateNormal;
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    [_sut setBackgroundImage:previousImage forState:state];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 20)];
    
    [_sut hnk_setBackgroundImage:image withKey:key forState:state];
    
    XCTAssertEqualObjects(_sut.hnk_backgroundImageFetcher.cacheKey, key,  @"");
    XCTAssertEqualObjects([_sut backgroundImageForState:state], previousImage, @"");
}

- (void)testSetBackgroundImageWithKeyPlaceholder_MemoryCacheHit
{
    NSString *key = self.name;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    UIImage *placeholder = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 20)];
    HNKCacheFormat *format = _sut.hnk_backgroundImageFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_sut hnk_setBackgroundImage:image withKey:key forState:UIControlStateNormal placeholder:placeholder];
    
    XCTAssertNil(_sut.hnk_backgroundImageFetcher,  @"");
    XCTAssertEqualObjects([_sut backgroundImageForState:UIControlStateNormal], image, @"");
}

- (void)testSetBackgroundImageWithKeyPlaceholder_MemoryCacheMiss
{
    NSString *key = self.name;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 20)];
    UIImage *placeholder = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    
    [_sut hnk_setBackgroundImage:image withKey:key forState:UIControlStateNormal placeholder:placeholder];
    
    XCTAssertEqualObjects(_sut.hnk_backgroundImageFetcher.cacheKey, key,  @"");
    XCTAssertEqualObjects([_sut backgroundImageForState:UIControlStateNormal], placeholder, @"");
}

- (void)testSetBackgroundImageWithKeyPlaceholder_ImageSet_MemoryCacheMiss
{
    NSString *key = self.name;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 20)];
    UIImage *placeholder = [UIImage hnk_imageWithColor:[UIColor yellowColor] size:CGSizeMake(10, 20)];
    const UIControlState state = UIControlStateNormal;
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    [_sut setBackgroundImage:previousImage forState:state];
    
    [_sut hnk_setBackgroundImage:image withKey:key forState:state placeholder:placeholder];
    
    XCTAssertEqualObjects(_sut.hnk_backgroundImageFetcher.cacheKey, key,  @"");
    XCTAssertEqualObjects([_sut backgroundImageForState:state], placeholder, @"");
}

- (void)testSetBackgroundImageWithKeyPlaceholderSuccessFailure_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    HNKCacheFormat *format = _sut.hnk_backgroundImageFormat;
    NSString *key = self.name;
    const UIControlState state = UIControlStateNormal;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    __block BOOL success = NO;
    [_sut hnk_setBackgroundImage:image withKey:key forState:state placeholder:nil success:^(UIImage *result) {
        XCTAssertEqualObjects(result, image, @"");
        success = YES;
    } failure:^(NSError *error) {
        XCTFail(@"");
    }];
    
    XCTAssertTrue(success, @"");
    XCTAssertNil(_sut.hnk_backgroundImageFetcher, @"");
    XCTAssertNil([_sut backgroundImageForState:state], @"");
}

- (void)testSetBackgroundImageWithKeyPlaceholderSuccessFailure_SuccessNil_MemoryCacheHit
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    NSString *key = self.name;
    HNKCacheFormat *format = _sut.hnk_backgroundImageFormat;
    const UIControlState state = UIControlStateNormal;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_sut hnk_setBackgroundImage:image withKey:key forState:state placeholder:nil success:nil failure:^(NSError *error) {
        XCTFail(@"");
    }];
    
    XCTAssertNil(_sut.hnk_backgroundImageFetcher, @"");
    XCTAssertEqualObjects([_sut backgroundImageForState:state], image, @"");
}

- (void)testSetBackgroundImageWithKeyPlaceholderSuccessFailure_MemoryCacheMiss
{
    NSString *key = self.name;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    const UIControlState state = UIControlStateNormal;
    
    [_sut hnk_setBackgroundImage:image withKey:key forState:state placeholder:nil success:nil failure:nil];
    
    XCTAssertEqualObjects(_sut.hnk_backgroundImageFetcher.cacheKey, key,  @"");
    XCTAssertNil([_sut backgroundImageForState:state], @"");
}

- (void)testSetBackgroundImageWithKeyPlaceholderSuccessFailure_ImageSet_MemoryCacheMiss
{
    UIImage *previousImage = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(1, 1)];
    const UIControlState state = UIControlStateNormal;
    [_sut setBackgroundImage:previousImage forState:state];
    NSString *key = self.name;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(1, 1)];
    
    [_sut hnk_setBackgroundImage:image withKey:key forState:state placeholder:nil success:nil failure:nil];
    
    XCTAssertEqualObjects(_sut.hnk_backgroundImageFetcher.cacheKey, key,  @"");
    XCTAssertEqualObjects([_sut backgroundImageForState:state], previousImage, @"");
}

#pragma mark setBackgroundImageFromFile

- (void)testSetBackgroundImageFromFile_MemoryCacheHit_UIControlStateNormal
{
    NSString *path = [_directory stringByAppendingPathComponent:self.name];
    id<HNKFetcher> fetcher = [[HNKDiskFetcher alloc] initWithPath:path];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    HNKCacheFormat *format = _sut.hnk_backgroundImageFormat;
    [[HNKCache sharedCache] setImage:image forKey:fetcher.cacheKey formatName:format.name];
    const UIControlState state = UIControlStateNormal;
    
    [_sut hnk_setBackgroundImageFromFile:path forState:state];
    
    XCTAssertNil(_sut.hnk_backgroundImageFetcher,  @"");
    XCTAssertEqualObjects([_sut backgroundImageForState:state], image, @"");
}

- (void)testSetBackgroundImageFromFilePlaceholder_MemoryCacheMiss_UIControlStateSelected
{
    NSString *path = [_directory stringByAppendingPathComponent:self.name];
    id<HNKFetcher> fetcher = [[HNKDiskFetcher alloc] initWithPath:path];
    UIImage *placeholder = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    const UIControlState state = UIControlStateSelected;
    
    [_sut hnk_setBackgroundImageFromFile:path forState:state placeholder:placeholder];
    
    XCTAssertEqualObjects(_sut.hnk_backgroundImageFetcher.cacheKey, fetcher.cacheKey,  @"");
    XCTAssertEqualObjects([_sut backgroundImageForState:state], placeholder, @"");
}

- (void)testSetBackgroundImageFromFilePlaceholderSuccessFailure_MemoryCacheHit
{
    NSString *path = [_directory stringByAppendingPathComponent:self.name];
    id<HNKFetcher> fetcher = [[HNKDiskFetcher alloc] initWithPath:path];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    HNKCacheFormat *format = _sut.hnk_backgroundImageFormat;
    [[HNKCache sharedCache] setImage:image forKey:fetcher.cacheKey formatName:format.name];
    const UIControlState state = UIControlStateNormal;
    
    __block BOOL success = NO;
    [_sut hnk_setBackgroundImageFromFile:path forState:state placeholder:nil success:^(UIImage *result) {
        XCTAssertEqualObjects(result, image, @"");
        success = YES;
    } failure:^(NSError *error) {
        XCTFail(@"");
    }];
    
    XCTAssertTrue(success, @"");
    XCTAssertNil(_sut.hnk_backgroundImageFetcher, @"");
    XCTAssertNil([_sut backgroundImageForState:state], @"");
}

#pragma mark setBackgroundImageFromURL

- (void)testSetBackgroundImageFromURL_MemoryCacheHit_UIControlStateNormal
{
    NSURL *URL = [NSURL URLWithString:@"http://haneke.io/image.jpg"];
    id<HNKFetcher> fetcher = [[HNKNetworkFetcher alloc] initWithURL:URL];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    HNKCacheFormat *format = _sut.hnk_backgroundImageFormat;
    [[HNKCache sharedCache] setImage:image forKey:fetcher.cacheKey formatName:format.name];
    const UIControlState state = UIControlStateNormal;
    
    [_sut hnk_setBackgroundImageFromURL:URL forState:state];
    
    XCTAssertNil(_sut.hnk_backgroundImageFetcher,  @"");
    XCTAssertEqualObjects([_sut backgroundImageForState:state], image, @"");
}

- (void)testSetBackgroundImageFromURLPlaceholder_MemoryCacheMiss_UIControlStateSelected
{
    NSURL *URL = [NSURL URLWithString:@"http://haneke.io/image.jpg"];
    id<HNKFetcher> fetcher = [[HNKNetworkFetcher alloc] initWithURL:URL];
    UIImage *placeholder = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    const UIControlState state = UIControlStateSelected;
    
    [_sut hnk_setBackgroundImageFromURL:URL forState:state placeholder:placeholder];
    
    XCTAssertEqualObjects(_sut.hnk_backgroundImageFetcher.cacheKey, fetcher.cacheKey,  @"");
    XCTAssertEqualObjects([_sut backgroundImageForState:state], placeholder, @"");
}

- (void)testSetBackgroundImageFromURLPlaceholderSuccessFailure_MemoryCacheHit
{
    NSURL *URL = [NSURL URLWithString:@"http://haneke.io/image.jpg"];
    id<HNKFetcher> fetcher = [[HNKNetworkFetcher alloc] initWithURL:URL];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    HNKCacheFormat *format = _sut.hnk_backgroundImageFormat;
    [[HNKCache sharedCache] setImage:image forKey:fetcher.cacheKey formatName:format.name];
    const UIControlState state = UIControlStateNormal;
    
    __block BOOL success = NO;
    [_sut hnk_setBackgroundImageFromURL:URL forState:state placeholder:nil success:^(UIImage *result) {
        XCTAssertEqualObjects(result, image, @"");
        success = YES;
    } failure:^(NSError *error) {
        XCTFail(@"");
    }];
    
    XCTAssertTrue(success, @"");
    XCTAssertNil(_sut.hnk_backgroundImageFetcher, @"");
    XCTAssertNil([_sut backgroundImageForState:state], @"");
}

#pragma mark setBackgroundImageFromFetcher

- (void)testSetBackgroundImageFromFetcher_MemoryCacheHit_UIControlStateNormal
{
    id<HNKFetcher> fetcher = [[HNKSimpleFetcher alloc] initWithKey:self.name image:nil];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    HNKCacheFormat *format = _sut.hnk_backgroundImageFormat;
    [[HNKCache sharedCache] setImage:image forKey:fetcher.cacheKey formatName:format.name];
    const UIControlState state = UIControlStateNormal;
    
    [_sut hnk_setBackgroundImageFromFetcher:fetcher forState:state];
    
    XCTAssertNil(_sut.hnk_backgroundImageFetcher,  @"");
    XCTAssertEqualObjects([_sut backgroundImageForState:state], image, @"");
}

- (void)testSetBackgroundImageFromFetcherLPlaceholder_MemoryCacheMiss_UIControlStateSelected
{
    id<HNKFetcher> fetcher = [[HNKSimpleFetcher alloc] initWithKey:self.name image:nil];
    UIImage *placeholder = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    const UIControlState state = UIControlStateSelected;
    
    [_sut hnk_setBackgroundImageFromFetcher:fetcher forState:state placeholder:placeholder];
    
    XCTAssertEqualObjects(_sut.hnk_backgroundImageFetcher, fetcher,  @"");
    XCTAssertEqualObjects([_sut backgroundImageForState:state], placeholder, @"");
}

- (void)testSetBackgroundImageFromFetcherPlaceholderSuccessFailure_MemoryCacheHit
{
    id<HNKFetcher> fetcher = [[HNKSimpleFetcher alloc] initWithKey:self.name image:nil];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    HNKCacheFormat *format = _sut.hnk_backgroundImageFormat;
    [[HNKCache sharedCache] setImage:image forKey:fetcher.cacheKey formatName:format.name];
    const UIControlState state = UIControlStateNormal;
    
    __block BOOL success = NO;
    [_sut hnk_setBackgroundImageFromFetcher:fetcher forState:state placeholder:nil success:^(UIImage *result) {
        XCTAssertEqualObjects(result, image, @"");
        success = YES;
    } failure:^(NSError *error) {
        XCTFail(@"");
    }];
    
    XCTAssertTrue(success, @"");
    XCTAssertNil(_sut.hnk_backgroundImageFetcher, @"");
    XCTAssertNil([_sut backgroundImageForState:state], @"");
}

#pragma mark cancelSetBackgroundImage

- (void)testCancelSetBackgroundImage_NoRequest
{
    [_sut hnk_cancelSetBackgroundImage];
    
    XCTAssertNil(_sut.hnk_backgroundImageFetcher, @"");
}

- (void)testCancelSetBackgroundImage_After
{
    NSURL *url = [NSURL URLWithString:@"http://imgs.xkcd.com/comics/election.png"];
    [_sut hnk_setBackgroundImageFromURL:url forState:UIControlStateHighlighted placeholder:nil success:^(UIImage *image) {
        XCTFail(@"Unexpected success");
    } failure:^(NSError *error) {
        XCTFail(@"Unexpected success");
    }];
    
    [_sut hnk_cancelSetBackgroundImage];
    
    XCTAssertNil(_sut.hnk_backgroundImageFetcher, @"");
    [self hnk_waitFor:0.1];
}

#pragma mark Helpers

- (void)_testSetImageWithKey_MemoryCacheHit_state:(UIControlState)state
{
    NSString *key = self.name;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    
    HNKCacheFormat *format = _sut.hnk_imageFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_sut hnk_setImage:image withKey:key forState:state];
    
    XCTAssertNil(_sut.hnk_imageFetcher,  @"");
    XCTAssertEqualObjects([_sut imageForState:state], image, @"");
}

- (void)_testSetBackgroundImageWithKey_MemoryCacheHit_state:(UIControlState)state
{
    NSString *key = self.name;
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    
    HNKCacheFormat *format = _sut.hnk_backgroundImageFormat;
    [[HNKCache sharedCache] setImage:image forKey:key formatName:format.name];
    
    [_sut hnk_setBackgroundImage:image withKey:key forState:state];
    
    XCTAssertNil(_sut.hnk_backgroundImageFetcher,  @"");
    XCTAssertEqualObjects([_sut backgroundImageForState:state], image, @"");
}

@end
