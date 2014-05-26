//
//  HNKCache+DiskTests.m
//  Haneke
//
//  Created by Hermés Piqué on 26/05/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HNKCache.h"
#import "HNKCache+HanekeTestUtils.h"
#import "UIImage+HanekeTestUtils.h"

@interface HNKCache(Disk)

- (void)calculateDiskSizeOfFormat:(HNKCacheFormat*)format;

- (void)controlDiskCapacityOfFormat:(HNKCacheFormat*)format;

- (void)enumeratePreloadImagesOfFormat:(HNKCacheFormat*)format usingBlock:(void(^)(NSString *key, UIImage *image))block;

- (NSString*)pathForKey:(NSString*)key format:(HNKCacheFormat*)format;

- (void)setDiskImage:(UIImage*)image forKey:(NSString*)key format:(HNKCacheFormat*)format;

- (void)updateAccessDateOfImage:(UIImage*)image key:(NSString*)key format:(HNKCacheFormat*)format;

@end

@interface HNKCache_DiskTests : XCTestCase

@end

@implementation HNKCache_DiskTests {
    HNKCache *_cache;
    HNKCacheFormat *_diskFormat;
}

- (void)setUp
{
    [super setUp];
    _cache = [[HNKCache alloc] initWithName:@"disk"];
    _diskFormat = [_cache registerFormatWithSize:CGSizeMake(1, 1)];
    _diskFormat.diskCapacity = 1 * 1024 * 1024;
}

- (void)tearDown
{
    [super tearDown];
    [_cache removeImagesOfFormatNamed:_diskFormat.name];
}

- (void)testSetDiskImage_LongKey
{
    NSMutableString *key = [NSMutableString string];
    for (NSInteger i = 0; i < NAME_MAX + 1; i++)
    {
        [key appendString:@"a"];
    }
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor whiteColor] size:CGSizeMake(1, 1)];
    [_cache setDiskImage:image forKey:key format:_diskFormat];
    
    XCTAssertTrue(_diskFormat.diskSize > 0, @"");
}

@end
