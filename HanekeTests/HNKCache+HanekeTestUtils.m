//
//  HNKCache+HanekeTestUtils.m
//  Haneke
//
//  Created by Hermes Pique on 20/02/14.
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

#import "HNKCache+HanekeTestUtils.h"
#import "HNKSimpleFetcher.h"
#import <OCMock/OCMock.h>

@implementation HNKCache (HanekeTestUtils)

+ (id)entityWithKey:(NSString*)key image:(UIImage*)image
{
    return [[HNKSimpleFetcher alloc] initWithKey:key image:image];
}

- (HNKCacheFormat*)registerFormatWithSize:(CGSize)size
{
    static NSUInteger FormatIndex = 0;
    NSString *name = [NSString stringWithFormat:@"format%ld", (long)FormatIndex];
    FormatIndex++;
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:name];
    format.size = size;
    [self registerFormat:format];
    return format;
}

@end
