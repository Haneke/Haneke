//
//  HNKNetworkFetcherTests.m
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
#import "HNKNetworkFetcher.h"
#import "UIImage+HanekeTestUtils.h"
#import "XCTestCase+HanekeTestUtils.h"
#import <OHHTTPStubs/OHHTTPStubs.h>

@interface HNKNetworkFetcherTests : XCTestCase

@end

@implementation HNKNetworkFetcherTests {
    HNKNetworkFetcher *_sut;
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

- (void)testURL
{
    _sut = [[HNKNetworkFetcher alloc] initWithURL:_URL];

    XCTAssertEqualObjects(_sut.URL, _URL, @"");
}

- (void)testKey
{
    _sut = [[HNKNetworkFetcher alloc] initWithURL:_URL];

    XCTAssertEqualObjects(_sut.key, _URL.absoluteString, @"");
}

- (void)testFetchImage_Success_StatusCode200
{
    [self _testFetchImage_Success_StatusCode:200];
}

- (void)testFetchImage_Success_StatusCode201
{
    [self _testFetchImage_Success_StatusCode:201];
}

- (void)testFetchImage_Failure_InvalidStatusCode_401
{
    [self _testFetchImage_Failure_InvalidStatusCode:401];
}

- (void)testFetchImage_Failure_InvalidStatusCode_402
{
    [self _testFetchImage_Failure_InvalidStatusCode:402];
}

- (void)testFetchImage_Failure_InvalidStatusCode_403
{
    [self _testFetchImage_Failure_InvalidStatusCode:403];
}

- (void)testFetchImage_Failure_InvalidStatusCode_404
{
    [self _testFetchImage_Failure_InvalidStatusCode:404];
}

- (void)testFetchImage_Failure_DownloadError
{
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:_URL.absoluteString];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithError:error];
    }];
    _sut = [[HNKNetworkFetcher alloc] initWithURL:_URL];
    XCTestExpectation *expectation = [self expectationWithDescription:self.name];

    [_sut fetchImageWithSuccess:^(UIImage *resultImage) {
        XCTFail(@"Expected to fail");
    } failure:^(NSError *resultError) {
        XCTAssertEqual(resultError.code, error.code, @"");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testFetchImage_Failure_HNKNetworkFetcherInvalidDataError
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:_URL.absoluteString];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSData *data = [NSData data];
        return [OHHTTPStubsResponse responseWithData:data statusCode:200 headers:nil];
    }];
    _sut = [[HNKNetworkFetcher alloc] initWithURL:_URL];
    XCTestExpectation *expectation = [self expectationWithDescription:self.name];

    [_sut fetchImageWithSuccess:^(UIImage *resultImage) {
        XCTFail(@"Expected to fail");
    } failure:^(NSError *error) {
        XCTAssertEqualObjects(error.domain, HNKErrorDomain, @"");
        XCTAssertEqual(error.code, HNKErrorNetworkFetcherInvalidData, @"");
        XCTAssertNotNil(error.localizedDescription, @"");
        XCTAssertEqualObjects(error.userInfo[NSURLErrorKey], _URL, @"");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testFetchImage_Failure_HNKNetworkFetcherMissingDataError
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:_URL.absoluteString];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {

        UIImage *image = [UIImage hnk_imageWithColor:[UIColor whiteColor] size:CGSizeMake(5, 5)];
        NSData *data = UIImageJPEGRepresentation(image, 1);
        NSString *contentLengthString = [NSString stringWithFormat:@"%ld", (long)data.length * 10];
        OHHTTPStubsResponse *response = [OHHTTPStubsResponse responseWithData:data statusCode:200 headers:nil];
        response.httpHeaders = @{@"Content-Length": contentLengthString}; // See: https://github.com/AliSoftware/OHHTTPStubs/pull/62
        return response;
    }];

    _sut = [[HNKNetworkFetcher alloc] initWithURL:_URL];

    XCTestExpectation *expectation = [self expectationWithDescription:self.name];

    [_sut fetchImageWithSuccess:^(UIImage *resultImage) {
        XCTFail(@"Expected to fail");
    } failure:^(NSError *error) {
        XCTAssertEqualObjects(error.domain, HNKErrorDomain, @"");
        XCTAssertEqual(error.code, HNKErrorNetworkFetcherMissingData, @"");
        XCTAssertNotNil(error.localizedDescription, @"");
        XCTAssertEqualObjects(error.userInfo[NSURLErrorKey], _URL, @"");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
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

    _sut = [[HNKNetworkFetcher alloc] initWithURL:_URL];
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
    _sut = [[HNKNetworkFetcher alloc] initWithURL:_URL];

    [_sut cancelFetch];
}

- (void)testURLSession
{
    _sut = [[HNKNetworkFetcher alloc] initWithURL:_URL];
    XCTAssertEqualObjects(_sut.URLSession, [NSURLSession sharedSession], @"");
}

#pragma mark Helpers

- (void)_testFetchImage_Success_StatusCode:(int)statusCode
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor whiteColor] size:CGSizeMake(5, 5)];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:_URL.absoluteString];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSData *data = UIImagePNGRepresentation(image);
        return [OHHTTPStubsResponse responseWithData:data statusCode:statusCode headers:nil];
    }];

    _sut = [[HNKNetworkFetcher alloc] initWithURL:_URL];

    XCTestExpectation *expectation = [self expectationWithDescription:self.name];

    [_sut fetchImageWithSuccess:^(UIImage *resultImage) {
        XCTAssertTrue([resultImage hnk_isEqualToImage:image], @"");
        [expectation fulfill];
    } failure:^(NSError *error) {
        XCTFail(@"Expected to succeed");

    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)_testFetchImage_Failure_InvalidStatusCode:(int)statusCode
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:_URL.absoluteString];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSData *data = [@"404" dataUsingEncoding:NSUTF8StringEncoding];
        return [OHHTTPStubsResponse responseWithData:data statusCode:statusCode headers:nil];
    }];
    _sut = [[HNKNetworkFetcher alloc] initWithURL:_URL];

    XCTestExpectation *expectation = [self expectationWithDescription:self.name];

    [_sut fetchImageWithSuccess:^(UIImage *resultImage) {
        XCTFail(@"Expected to fail");
    } failure:^(NSError *error) {
        XCTAssertEqualObjects(error.domain, HNKErrorDomain, @"");
        XCTAssertEqual(error.code, HNKErrorNetworkFetcherInvalidStatusCode, @"");
        XCTAssertNotNil(error.localizedDescription, @"");
        XCTAssertEqualObjects(error.userInfo[NSURLErrorKey], _URL, @"");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
