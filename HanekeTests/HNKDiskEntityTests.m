//
//  HNKDiskEntityTests.m
//  Haneke
//
//  Created by Hermes Pique on 8/20/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HNKDiskEntity.h"
#import "UIImage+HanekeTestUtils.h"
#import "XCTestCase+HanekeTestUtils.h"

@interface HNKDiskEntityTests : XCTestCase

@end

@implementation HNKDiskEntityTests {
    HNKDiskEntity *_sut;
    NSString *_directory;
}

- (void)setUp
{
    _directory = NSHomeDirectory();
    _directory = [_directory stringByAppendingPathComponent:@"io.haneke"];
    _directory = [_directory stringByAppendingPathComponent:NSStringFromClass(self.class)];
    [[NSFileManager defaultManager] createDirectoryAtPath:_directory withIntermediateDirectories:YES attributes:nil error:nil];
}

- (void)tearDown
{
    NSString *directory = NSHomeDirectory();
    directory = [directory stringByAppendingPathComponent:@"io.haneke"];
    [[NSFileManager defaultManager] removeItemAtPath:directory error:nil];
    [super tearDown];
}

- (void)testCacheKey
{
    NSString *path = [_directory stringByAppendingPathComponent:self.name];
    _sut = [[HNKDiskEntity alloc] initWithPath:path];
    
    XCTAssertEqualObjects(_sut.cacheKey, path, @"");
}

- (void)testFetchImage_Success
{
    NSString *path = [_directory stringByAppendingPathComponent:self.name];
    _sut = [[HNKDiskEntity alloc] initWithPath:path];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    NSData *data = UIImagePNGRepresentation(image);
    [data writeToFile:path atomically:YES];
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_sut fetchImageWithSuccess:^(UIImage *resultImage) {
            XCTAssertTrue([resultImage hnk_isEqualToImage:image], @"");
            dispatch_semaphore_signal(semaphore);
        } failure:^(NSError *error) {
            XCTFail(@"Expected to succeed");
            dispatch_semaphore_signal(semaphore);
        }];
    }];
}

- (void)testFetchImage_Failure_NSFileReadNoSuchFileError
{
    NSString *path = [_directory stringByAppendingPathComponent:self.name];
    _sut = [[HNKDiskEntity alloc] initWithPath:path];
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_sut fetchImageWithSuccess:^(UIImage *resultImage) {
            XCTFail(@"Expected to fail");
            dispatch_semaphore_signal(semaphore);
        } failure:^(NSError *error) {
            XCTAssertEqual(error.code, NSFileReadNoSuchFileError, @"");
            dispatch_semaphore_signal(semaphore);
        }];
    }];
}

- (void)testFetchImage_Failure_HNKDiskEntityInvalidDataError
{
    NSString *path = [_directory stringByAppendingPathComponent:self.name];
    _sut = [[HNKDiskEntity alloc] initWithPath:path];
    NSData *data = [NSData data];
    [data writeToFile:path atomically:YES];
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_sut fetchImageWithSuccess:^(UIImage *resultImage) {
            XCTFail(@"Expected to fail");
            dispatch_semaphore_signal(semaphore);
        } failure:^(NSError *error) {
            XCTAssertEqualObjects(error.domain, HNKErrorDomain, @"");
            XCTAssertEqual(error.code, HNKDiskEntityInvalidDataError, @"");
            XCTAssertNotNil(error.localizedDescription, @"");
            XCTAssertEqualObjects(error.userInfo[NSFilePathErrorKey], path, @"");
            dispatch_semaphore_signal(semaphore);
        }];
    }];
}

- (void)testCancelFetch
{
    NSString *path = [_directory stringByAppendingPathComponent:self.name];
    _sut = [[HNKDiskEntity alloc] initWithPath:path];
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 20)];
    NSData *data = UIImagePNGRepresentation(image);
    [data writeToFile:path atomically:YES];
    [_sut fetchImageWithSuccess:^(UIImage *image) {
        XCTFail(@"Unexpected success");
    } failure:^(NSError *error) {
        XCTFail(@"Unexpected failure");
    }];
    
    [_sut cancelFetch];
    
    [self hnk_waitFor:0.1];
}

- (void)testCancelFetch_NoFetch
{
    NSString *path = [_directory stringByAppendingPathComponent:self.name];
    _sut = [[HNKDiskEntity alloc] initWithPath:path];
    
    [_sut cancelFetch];
}

@end
