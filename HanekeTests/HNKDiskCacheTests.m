//
//  HNKDiskCacheTests.m
//  Haneke
//
//  Created by Hermes Pique on 8/21/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HNKDiskCache.h"
#import "XCTestCase+HanekeTestUtils.h"

@interface HNKDiskCacheTests : XCTestCase

@end

@implementation HNKDiskCacheTests {
    HNKDiskCache *_sut;
    NSString *_directory;
}

- (void)setUp
{
    [super setUp];
    _directory = NSHomeDirectory();
    _directory = [_directory stringByAppendingPathComponent:@"io.haneke"];
    _directory = [_directory stringByAppendingPathComponent:NSStringFromClass(self.class)];
    _directory = [_directory stringByAppendingPathComponent:self.name];
    [[NSFileManager defaultManager] createDirectoryAtPath:_directory withIntermediateDirectories:YES attributes:nil error:nil];
}

- (void)tearDown
{
    NSString *directory = NSHomeDirectory();
    directory = [directory stringByAppendingPathComponent:@"io.haneke"];
    [[NSFileManager defaultManager] removeItemAtPath:directory error:nil];
    [super tearDown];
}

- (void)testInit
{
    unsigned long long capacity = 100;
    
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:capacity];
    
    XCTAssertNotNil(_sut.queue, @"");
    XCTAssertEqual(_sut.size, 0, @"");
    XCTAssertEqual(_sut.capacity, capacity, @"");
}

- (void)testInit_CalculateSize
{
    const unsigned long long capacity = 100;
    const unsigned long long size = 10;
    [self _writeDataWithSize:size];
    
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:capacity];
    
    dispatch_sync(_sut.queue, ^{
        XCTAssertEqual(_sut.size, size, @"");
    });
}

- (void)testInit_ControlCapacity
{
    const unsigned long long capacity = 0;
    [self _writeDataWithSize:10];
    
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:capacity];
    
    dispatch_sync(_sut.queue, ^{
        XCTAssertEqual(_sut.size, 0, @"");
    });
}

- (void)testSetCapacity_Zero
{
    const unsigned long long size = 10;
    [self _writeDataWithSize:size];
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:size * 2];
    dispatch_sync(_sut.queue, ^{
        XCTAssertEqual(_sut.size, size, @"");
    });

    _sut.capacity = 0;
    
    dispatch_sync(_sut.queue, ^{
        XCTAssertEqual(_sut.size, 0, @"");
    });
}

- (void)testSetData
{
    const long size = 5;
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:size * 2];
    NSData *data = [self _dataWithSize:size];
    NSString *key = self.name;
    
    [_sut setData:data forKey:key];
    
    dispatch_sync(_sut.queue, ^{
        XCTAssertEqual(_sut.size, size, @"");
    });
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_sut fetchDataForKey:key success:^(NSData *resultData) {
            XCTAssertEqualObjects(data, resultData, @"");
            dispatch_semaphore_signal(semaphore);
        } failure:^(NSError *error) {
            XCTFail(@"Expected success");
            dispatch_semaphore_signal(semaphore);
        }];
    }];
}

- (void)testSetData_LongKey
{
    const long size = 5;
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:size * 2];
    NSData *data = [self _dataWithSize:size];
    NSString *key = @"12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890";
    
    [_sut setData:data forKey:key];
    
    dispatch_sync(_sut.queue, ^{
        XCTAssertEqual(_sut.size, size, @"");
    });
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_sut fetchDataForKey:key success:^(NSData *resultData) {
            XCTAssertEqualObjects(data, resultData, @"");
            dispatch_semaphore_signal(semaphore);
        } failure:^(NSError *error) {
            XCTFail(@"Expected success");
            dispatch_semaphore_signal(semaphore);
        }];
    }];
}

- (void)testSetData_KeyWithInvalidCharacters
{
    const long size = 7;
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:size * 2];
    NSData *data = [self _dataWithSize:size];
    NSString *key = @":/\\";
    
    [_sut setData:data forKey:key];
    
    dispatch_sync(_sut.queue, ^{
        XCTAssertEqual(_sut.size, size, @"");
    });
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_sut fetchDataForKey:key success:^(NSData *resultData) {
            XCTAssertEqualObjects(data, resultData, @"");
            dispatch_semaphore_signal(semaphore);
        } failure:^(NSError *error) {
            XCTFail(@"Expected success");
            dispatch_semaphore_signal(semaphore);
        }];
    }];
}

- (void)testSetData_Ovewrite
{
    const long size1 = 7;
    const long size2 = 12;
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:MAX(size1, size2)];
    NSData *data1 = [self _dataWithSize:size1];
    NSString *key = self.name;
    [_sut setData:data1 forKey:key];
    dispatch_sync(_sut.queue, ^{
        XCTAssertEqual(_sut.size, size1, @"");
    });
    NSData *data2 = [self _dataWithSize:size2];

    [_sut setData:data2 forKey:key];
    
    dispatch_sync(_sut.queue, ^{
        XCTAssertEqual(_sut.size, size2, @"");
    });
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_sut fetchDataForKey:key success:^(NSData *resultData) {
            XCTAssertEqualObjects(data2, resultData, @"");
            dispatch_semaphore_signal(semaphore);
        } failure:^(NSError *error) {
            XCTFail(@"Expected success");
            dispatch_semaphore_signal(semaphore);
        }];
    }];
}

#pragma mark Helpers

- (NSData*)_dataWithSize:(unsigned long long)size
{
    char bytes[size];
    NSData *data = [NSData dataWithBytes:bytes length:size];
    return data;
}

- (void)_writeDataWithSize:(unsigned long long)size
{
    static NSInteger i = 0;
    NSData *data = [self _dataWithSize:size];
    NSString *path = [_directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld", (long)i]];
    i++;
    [data writeToFile:path atomically:YES];
}

@end
