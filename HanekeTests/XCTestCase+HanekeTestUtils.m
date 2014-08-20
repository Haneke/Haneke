//
//  XCTestCase+HanekeTestUtils.m
//  Haneke
//
//  Created by Hermés Piqué on 09/03/14.
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

#import "XCTestCase+HanekeTestUtils.h"

@implementation XCTestCase (HanekeTestUtils)

- (void)hnk_testAsyncBlock:(void(^)(dispatch_semaphore_t))block
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    block(semaphore);
    NSInteger i = 0;
    static const NSTimeInterval IterationDelay = 0.005;
    static const NSInteger MaxIterations = 400;
    while (i < MaxIterations && dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
    {
        [self hnk_waitFor:IterationDelay];
        i++;
    }
    if (i >= MaxIterations)
    {
        XCTFail(@"Async unit test took too long to complete.");
    }
}

- (void)hnk_waitFor:(NSTimeInterval)timeInterval
{
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:timeInterval]];
}

@end
