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

@interface NSString (hnk_utils)

- (NSString*)hnk_MD5String;

- (NSString*)hnk_valueForExtendedFileAttribute:(NSString*)attribute;

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

- (void)testSetDiskImage_JPEG
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor whiteColor] size:CGSizeMake(1, 1)];
    NSString *key = @"test.jpg";
    
    [_cache setDiskImage:image forKey:key format:_diskFormat];
    
    NSData *data = UIImageJPEGRepresentation(image, _diskFormat.compressionQuality);
    XCTAssertEqual(_diskFormat.diskSize, data.length, @"");
    NSString *path = [_cache pathForKey:key format:_diskFormat];
    NSString *extendedFileAttributeKey = [path hnk_valueForExtendedFileAttribute:HNKExtendedFileAttributeKey];
    XCTAssertEqualObjects(extendedFileAttributeKey, key, @"");
}

- (void)testSetDiskImage_PNG
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor whiteColor] size:CGSizeMake(1, 1) opaque:NO];
    NSData *PNGData = UIImagePNGRepresentation(image);
    NSData *JPEGData = UIImageJPEGRepresentation(image, _diskFormat.compressionQuality);
    NSString *key = @"test.jpg";
    
    XCTAssertNotEqual(JPEGData.length, PNGData.length, @"");
    
    [_cache setDiskImage:image forKey:key format:_diskFormat];
    
    XCTAssertEqual(_diskFormat.diskSize, PNGData.length, @"");
    NSString *path = [_cache pathForKey:key format:_diskFormat];
    NSString *extendedFileAttributeKey = [path hnk_valueForExtendedFileAttribute:HNKExtendedFileAttributeKey];
    XCTAssertEqualObjects(extendedFileAttributeKey, key, @"");
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
    
    NSData *data = UIImageJPEGRepresentation(image, _diskFormat.compressionQuality);
    XCTAssertEqual(_diskFormat.diskSize, data.length, @"");
    NSString *path = [_cache pathForKey:key format:_diskFormat];
    NSString *extendedFileAttributeKey = [path hnk_valueForExtendedFileAttribute:HNKExtendedFileAttributeKey];
    XCTAssertEqualObjects(extendedFileAttributeKey, key, @"");
}

- (void)testSetDiskImage_Nil
{
    [_cache setDiskImage:nil forKey:@"test.jpg" format:_diskFormat];
    
    XCTAssertEqual(_diskFormat.diskSize, 0, @"");
}

- (void)testSetDiskImage_NilToRemove
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor whiteColor] size:CGSizeMake(1, 1)];
    NSString *key = @"test.jpg";
    [_cache setDiskImage:image forKey:key format:_diskFormat];
    XCTAssertTrue(_diskFormat.diskSize > 0, @"");
    
    [_cache setDiskImage:nil forKey:key format:_diskFormat];
    
    XCTAssertEqual(_diskFormat.diskSize, 0, @"");
}

@end
