//
//  XCTestCase+HanekeTestUtils.m
//  Haneke
//
//  Created by Hermés Piqué on 09/03/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "XCTestCase+HanekeTestUtils.h"

@implementation XCTestCase (HanekeTestUtils)

- (void)hnk_testAsyncBlock:(void(^)(dispatch_semaphore_t))block
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    block(semaphore);
    NSInteger i = 0;
    static const NSTimeInterval IterationDelay = 0.005;
    static const NSInteger MaxIterations = 100;
    while (i < MaxIterations && dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:IterationDelay]];
        i++;
    }
    if (i >= MaxIterations)
    {
        XCTFail(@"Async unit test took too long to complete.");
    }
}

@end
