//
//  HNKSimpleEntityTests.m
//  Haneke
//
//  Created by Hermes Pique on 8/20/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HNKSimpleEntity.h"
#import "UIImage+HanekeTestUtils.h"

@interface HNKSimpleEntityTests : XCTestCase

@end

@implementation HNKSimpleEntityTests {
    HNKSimpleEntity *_sut;
}

- (void)testCacheKey
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 10)];
    NSString *key = self.name;
    _sut = [[HNKSimpleEntity alloc] initWithKey:key image:image];
    
    XCTAssertEqualObjects(_sut.cacheKey, key, @"");
}

- (void)testFetchImage
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor greenColor] size:CGSizeMake(10, 10)];
    NSString *key = self.name;
    _sut = [[HNKSimpleEntity alloc] initWithKey:key image:image];

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
