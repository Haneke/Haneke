//
//  HNKSimpleFetcher.m
//  Haneke
//
//  Created by Hermes Pique on 8/19/14.
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

#import "HNKSimpleFetcher.h"

@implementation HNKSimpleFetcher {
    NSString *_key;
    UIImage *_image;
}

- (instancetype)initWithKey:(NSString*)key image:(UIImage*)image
{
    if (self = [super init])
    {
        _key = [key copy];
        _image = image;
    }
    return self;
}

- (NSString*)key
{
    return _key;
}

- (void)fetchImageWithSuccess:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;
{
    successBlock(_image);
}

@end
