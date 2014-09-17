//
//  HNKSimpleFetcherTests.m
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
#import "HNKSimpleFetcher.h"
#import "UIImage+HanekeTestUtils.h"

@interface HNKSimpleFetcherTests : XCTestCase

@end

@implementation HNKSimpleFetcherTests {
    HNKSimpleFetcher *_sut;
}

- (void)testCacheKey
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 10)];
    NSString *key = self.name;
    _sut = [[HNKSimpleFetcher alloc] initWithKey:key image:image];
    
    XCTAssertEqualObjects(_sut.cacheKey, key, @"");
}

- (void)testFetchImage
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 10)];
    NSString *key = self.name;
    _sut = [[HNKSimpleFetcher alloc] initWithKey:key image:image];

    __block BOOL success = NO;
    [_sut fetchImageWithSuccess:^(UIImage *resultImage) {
        XCTAssertEqualObjects(image, resultImage, @"");
        success = YES;
    } failure:^(NSError *error) {
        XCTFail(@"");
    }];
    
    XCTAssertTrue(success, @"");
}

@end
