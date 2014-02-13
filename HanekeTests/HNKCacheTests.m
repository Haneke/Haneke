//
//  HNKCacheTests.m
//  Haneke
//
//  Created by Hermes on 11/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HNKCache.h"
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

- (void)testClearFormat_Existing
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"format"];
    [_cache registerFormat:format];
    
    [_cache clearFormatNamed:format.name];
    XCTAssertTrue(format.diskSize == 0, @"");
}

- (void)testClearFormat_Inexisting
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"format"];
    [_cache clearFormatNamed:format.name];
}

- (void)testImageForEntity_Image
{
    UIImage *image = [HNKCacheTests imageWithColor:[UIColor redColor] size:CGSizeMake(10, 10)];
    id entity = [HNKCacheTests entityWithKey:@"1" data:nil image:image];
    HNKCacheFormat *format = [self registerFormatWithSize:CGSizeMake(1, 1)];
    
    UIImage *result = [_cache imageForEntity:entity formatName:format.name];
    CGSize resultSize = result.size;
    
    XCTAssertNotNil(result, @"");
    XCTAssertEqual(resultSize, format.size, @"");
}

- (void)testImageForEntity_Data
{
    UIImage *image = [HNKCacheTests imageWithColor:[UIColor redColor] size:CGSizeMake(10, 10)];
    NSData *data = UIImagePNGRepresentation(image);
    id entity = [HNKCacheTests entityWithKey:@"1" data:data image:nil];
    HNKCacheFormat *format = [self registerFormatWithSize:CGSizeMake(1, 1)];
    
    UIImage *result = [_cache imageForEntity:entity formatName:format.name];
    CGSize resultSize = result.size;
    
    XCTAssertNotNil(result, @"");
    XCTAssertEqual(resultSize, format.size, @"");
}

#pragma mark - Utils

- (HNKCacheFormat*)registerFormatWithSize:(CGSize)size
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"format"];
    format.size = size;
    [_cache registerFormat:format];
    return format;
}

+ (id)entityWithKey:(NSString*)key data:(NSData*)data image:(UIImage*)image
{
    id entity = [OCMockObject mockForProtocol:@protocol(HNKCacheEntity)];
    [[[entity stub] andReturn:key] cacheKey];
    [[[entity stub] andReturn:data] cacheOriginalData];
    [[[entity stub] andReturn:image] cacheOriginalImage];
    return entity;
}

+ (UIImage*)imageWithColor:(UIColor*)color size:(CGSize)size
{
    UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


@end
