//
//  HNKDiskCacheTests.m
//  Haneke
//
//  Created by Hermes Pique on 8/21/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:LONG_LONG_MAX];
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
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:LONG_LONG_MAX];
    NSData *data = [self _dataWithSize:size];
    NSString *key = self.name;

    [_sut setData:data forKey:key];

    dispatch_sync(_sut.queue, ^{
        XCTAssertEqual(_sut.size, size, @"");
    });
    XCTestExpectation *expectation = [self expectationWithDescription:self.name];

    [_sut fetchDataForKey:key success:^(NSData *resultData) {
        XCTAssertEqualObjects(data, resultData, @"");
        [expectation fulfill];
    } failure:^(NSError *error) {
        XCTFail(@"Expected success");
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testSetData_LongKey
{
    const long size = 5;
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:LONG_LONG_MAX];
    NSData *data = [self _dataWithSize:size];
    NSString *key = @"12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890";

    [_sut setData:data forKey:key];

    dispatch_sync(_sut.queue, ^{
        XCTAssertEqual(_sut.size, size, @"");
    });

    XCTestExpectation *expectation = [self expectationWithDescription:self.name];

    [_sut fetchDataForKey:key success:^(NSData *resultData) {
        XCTAssertEqualObjects(data, resultData, @"");
        [expectation fulfill];
    } failure:^(NSError *error) {
        XCTFail(@"Expected success");
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testSetData_KeyWithInvalidCharacters
{
    const long size = 7;
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:LONG_LONG_MAX];
    NSData *data = [self _dataWithSize:size];
    NSString *key = @":/\\";

    [_sut setData:data forKey:key];

    dispatch_sync(_sut.queue, ^{
        XCTAssertEqual(_sut.size, size, @"");
    });

    XCTestExpectation *expectation = [self expectationWithDescription:self.name];

    [_sut fetchDataForKey:key success:^(NSData *resultData) {
        XCTAssertEqualObjects(data, resultData, @"");
        [expectation fulfill];
    } failure:^(NSError *error) {
        XCTFail(@"Expected success");
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testSetData_Ovewrite
{
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:LONG_LONG_MAX];
    const long size1 = 7;
    NSData *data1 = [self _dataWithSize:size1];
    NSString *key = self.name;
    [_sut setData:data1 forKey:key];
    dispatch_sync(_sut.queue, ^{
        XCTAssertEqual(_sut.size, size1, @"");
    });
    const long size2 = 12;
    NSData *data2 = [self _dataWithSize:size2];

    [_sut setData:data2 forKey:key];

    dispatch_sync(_sut.queue, ^{
        XCTAssertEqual(_sut.size, size2, @"");
    });

    XCTestExpectation *expectation = [self expectationWithDescription:self.name];

    [_sut fetchDataForKey:key success:^(NSData *resultData) {
        XCTAssertEqualObjects(data2, resultData, @"");
        [expectation fulfill];
    } failure:^(NSError *error) {
        XCTFail(@"Expected success");
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testFetchDataForKey_Success
{
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:LONG_LONG_MAX];
    NSData *data = [self _dataWithSize:14];
    NSString *key = self.name;
    [_sut setData:data forKey:key];
    XCTestExpectation *expectation = [self expectationWithDescription:self.name];

    [_sut fetchDataForKey:key success:^(NSData *resultData) {
        XCTAssertEqualObjects(data, resultData, @"");
        [expectation fulfill];
    } failure:^(NSError *error) {
        XCTFail(@"Expected success");
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testFetchDataForKey_Failure
{
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:LONG_LONG_MAX];
    NSString *key = self.name;
    XCTestExpectation *expectation = [self expectationWithDescription:self.name];

    [_sut fetchDataForKey:key success:^(NSData *resultData) {
        XCTFail(@"Expected failure");
    } failure:^(NSError *error) {
        XCTAssertEqual(error.code, NSFileReadNoSuchFileError, @"");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testRemoveDataForKey
{
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:LONG_LONG_MAX];
    NSData *data = [self _dataWithSize:23];
    NSString *key = self.name;
    [_sut setData:data forKey:key];
    dispatch_sync(_sut.queue, ^{
        XCTAssertTrue(_sut.size > 0, @"");
    });

    [_sut removeDataForKey:key];
    dispatch_sync(_sut.queue, ^{
        XCTAssertEqual(_sut.size, 0, @"");
    });
}

- (void)testRemoveDataForKey_Inexisting
{
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:LONG_LONG_MAX];
    NSData *data = [self _dataWithSize:23];
    [_sut setData:data forKey:@"1"];
    dispatch_sync(_sut.queue, ^{
        XCTAssertTrue(_sut.size > 0, @"");
    });

    [_sut removeDataForKey:@"inexisting"];

    dispatch_sync(_sut.queue, ^{
        XCTAssertTrue(_sut.size > 0, @"");
    });
}

- (void)testRemoveAllData
{
    [self _writeDataWithSize:10];
    [self _writeDataWithSize:7];
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:LONG_LONG_MAX];
    dispatch_sync(_sut.queue, ^{
        XCTAssertTrue(_sut.size > 0, @"");
    });

    [_sut removeAllData];
    dispatch_sync(_sut.queue, ^{
        XCTAssertEqual(_sut.size, 0, @"");
    });
}

- (void)testRemoveAllData_ThenSetData {
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:LONG_LONG_MAX];

    [_sut removeAllData];

    NSData *data = [self _dataWithSize:23];
    [_sut setData:data forKey:@"1"];
    dispatch_sync(_sut.queue, ^{
        XCTAssertTrue(_sut.size > 0, @"");
    });
}

- (void)testEnumerateDataByAccessDateUsingBlock_One
{
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:LONG_LONG_MAX];
    NSData *data = [self _dataWithSize:8];
    NSString *key = self.name;
    [_sut setData:data forKey:key];

    XCTestExpectation *expectation = [self expectationWithDescription:self.name];

    [_sut enumerateDataByAccessDateUsingBlock:^(NSString *resultKey, NSData *resultData, NSDate *accessDate, BOOL *stop) {
        XCTAssertEqualObjects(resultKey, key, @"");
        XCTAssertEqualObjects(resultData, data, @"");
        XCTAssertNotNil(accessDate, @"");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testEnumerateDataByAccessDateUsingBlock_Two
{
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:LONG_LONG_MAX];
    NSData *data1 = [self _dataWithSize:8];
    NSString *key1 = @"1";
    [_sut setData:data1 forKey:key1];
    NSData *data2 = [self _dataWithSize:13];
    NSString *key2 = @"2";
    [_sut setData:data2 forKey:key2];

    __block NSInteger i = 0;

    XCTestExpectation *expectation = [self expectationWithDescription:self.name];

    [_sut enumerateDataByAccessDateUsingBlock:^(NSString *resultKey, NSData *resultData, NSDate *accessDate, BOOL *stop) {
        i++;
        if (i == 2) {
            [expectation fulfill];
        }
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testEnumerateDataByAccessDateUsingBlock_Empty
{
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:LONG_LONG_MAX];

    [_sut enumerateDataByAccessDateUsingBlock:^(NSString *key, NSData *data, NSDate *accessDate, BOOL *stop) {
        XCTFail(@"");
    }];
}

- (void)testUpdateAccessDateForKey_Inexisting_DataNil
{
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:LONG_LONG_MAX];
    NSString *key = self.name;

    [_sut updateAccessDateForKey:key data:nil];
}

- (void)testUpdateAccessDateForKey_Inexisting_Data
{
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:LONG_LONG_MAX];
    NSData *data = [self _dataWithSize:3];
    NSString *key = self.name;

    [_sut updateAccessDateForKey:key data:^NSData *{ return data; }];

    XCTestExpectation *expectation = [self expectationWithDescription:self.name];

    [_sut fetchDataForKey:key success:^(NSData *resultData) {
        XCTAssertEqualObjects(data, resultData, @"");
        [expectation fulfill];
    } failure:^(NSError *error) {
        XCTFail(@"Expected success");
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testUpdateAccessDateForKey_Existing
{
    _sut = [[HNKDiskCache alloc] initWithDirectory:_directory capacity:LONG_LONG_MAX];
    NSData *data = [self _dataWithSize:3];
    NSString *key = self.name;
    [_sut setData:data forKey:key];

    [_sut updateAccessDateForKey:key data:^NSData *{ return data; }];
}

#pragma mark Helpers

- (NSData*)_dataWithSize:(NSUInteger)size
{
    char bytes[size];
    NSData *data = [NSData dataWithBytes:bytes length:size];
    return data;
}

- (void)_writeDataWithSize:(NSUInteger)size
{
    static NSInteger i = 0;
    NSData *data = [self _dataWithSize:size];
    NSString *path = [_directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld", (long)i]];
    i++;
    [data writeToFile:path atomically:YES];
}

@end
