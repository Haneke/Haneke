//
//  XCTestCase+HanekeTestUtils.h
//  Haneke
//
//  Created by Hermés Piqué on 09/03/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface XCTestCase (HanekeTestUtils)

- (void)hnk_testAsyncBlock:(void(^)(dispatch_semaphore_t))block;

@end
