//
//  HNKNetworkEntityTests.m
//  Haneke
//
//  Created by Hermes Pique on 8/20/14.
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
#import "HNKNetworkEntity.h"
#import "UIImage+HanekeTestUtils.h"
#import "XCTestCase+HanekeTestUtils.h"
#import <OHHTTPStubs/OHHTTPStubs.h>

@interface HNKNetworkEntityTests : XCTestCase

@end

@implementation HNKNetworkEntityTests {
    HNKNetworkEntity *_sut;
    NSURL *_URL;
}

- (void)setUp
{
    _URL = [NSURL URLWithString:@"http://haneke.io/image.jpg"];
}

- (void)tearDown
{
    [OHHTTPStubs removeAllStubs];
    [super tearDown];
}

- (void)testCacheKey
{
    _sut = [[HNKNetworkEntity alloc] initWithURL:_URL];
    
    XCTAssertEqualObjects(_sut.cacheKey, _URL.absoluteString, @"");
}

- (void)testFetchImage_Success
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor whiteColor] size:CGSizeMake(5, 5)];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:_URL.absoluteString];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSData *data = UIImagePNGRepresentation(image);
        return [OHHTTPStubsResponse responseWithData:data statusCode:200 headers:nil];
    }];
    
    _sut = [[HNKNetworkEntity alloc] initWithURL:_URL];
    
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

- (void)testFetchImage_Failure_DownloadError
{
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:_URL.absoluteString];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithError:error];
    }];
    _sut = [[HNKNetworkEntity alloc] initWithURL:_URL];
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_sut fetchImageWithSuccess:^(UIImage *resultImage) {
            XCTFail(@"Expected to fail");
            dispatch_semaphore_signal(semaphore);
        } failure:^(NSError *resultError) {
            XCTAssertEqual(resultError.code, error.code, @"");
            dispatch_semaphore_signal(semaphore);
        }];
    }];
}

- (void)testFetchImage_Failure_HNKNetworkEntityInvalidDataError
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:_URL.absoluteString];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSData *data = [NSData data];
        return [OHHTTPStubsResponse responseWithData:data statusCode:200 headers:nil];
    }];
   _sut = [[HNKNetworkEntity alloc] initWithURL:_URL];
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_sut fetchImageWithSuccess:^(UIImage *resultImage) {
            XCTFail(@"Expected to fail");
            dispatch_semaphore_signal(semaphore);
        } failure:^(NSError *error) {
            XCTAssertEqualObjects(error.domain, HNKErrorDomain, @"");
            XCTAssertEqual(error.code, HNKNetworkEntityInvalidDataError, @"");
            XCTAssertNotNil(error.localizedDescription, @"");
            XCTAssertEqualObjects(error.userInfo[NSURLErrorKey], _URL, @"");
            dispatch_semaphore_signal(semaphore);
        }];
    }];
}

- (void)testFetchImage_Failure_HNKNetworkEntityMissingDataError
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:_URL.absoluteString];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        
        UIImage *image = [UIImage hnk_imageWithColor:[UIColor whiteColor] size:CGSizeMake(5, 5)];
        NSData *data = UIImageJPEGRepresentation(image, 1);
        NSString *contentLengthString = [NSString stringWithFormat:@"%lu", data.length * 10];
        OHHTTPStubsResponse *response = [OHHTTPStubsResponse responseWithData:data statusCode:200 headers:nil];
        response.httpHeaders = @{@"Content-Length": contentLengthString}; // See: https://github.com/AliSoftware/OHHTTPStubs/pull/62
        return response;
    }];

    _sut = [[HNKNetworkEntity alloc] initWithURL:_URL];
    
    [self hnk_testAsyncBlock:^(dispatch_semaphore_t semaphore) {
        [_sut fetchImageWithSuccess:^(UIImage *resultImage) {
            XCTFail(@"Expected to fail");
            dispatch_semaphore_signal(semaphore);
        } failure:^(NSError *error) {
            XCTAssertEqualObjects(error.domain, HNKErrorDomain, @"");
            XCTAssertEqual(error.code, HNKNetworkEntityMissingDataError, @"");
            XCTAssertNotNil(error.localizedDescription, @"");
            XCTAssertEqualObjects(error.userInfo[NSURLErrorKey], _URL, @"");
            dispatch_semaphore_signal(semaphore);
        }];
    }];
}

- (void)testCancelFetch
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor whiteColor] size:CGSizeMake(5, 5)];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:_URL.absoluteString];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSData *data = UIImagePNGRepresentation(image);
        return [OHHTTPStubsResponse responseWithData:data statusCode:200 headers:nil];
    }];
    
    _sut = [[HNKNetworkEntity alloc] initWithURL:_URL];
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
   _sut = [[HNKNetworkEntity alloc] initWithURL:_URL];

    [_sut cancelFetch];
}

@end
