//
//  HNKNetworkFetcher.h
//  Haneke
//
//  Created by Hermes Pique on 7/23/14.
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

#import <Foundation/Foundation.h>
#import "HNKCache.h"

enum
{
    HNKErrorNetworkFetcherInvalidData = -400,
    HNKErrorNetworkFetcherMissingData = -401,
    HNKErrorNetworkFetcherInvalidStatusCode = -402
};

/**
 Fetcher that can provide a network image. The key will be the absolute string of the given URL.
 */
@interface HNKNetworkFetcher : NSObject<HNKFetcher>

/**
 Initializes a fetcher with the given URL.
 @param URL Image URL.
 */
- (instancetype)initWithURL:(NSURL*)URL;

/**
 Image URL.
 */
@property (nonatomic, readonly) NSURL *URL;


/**
 Cancels the current fetch. When a fetch is cancelled it should not call any of the provided blocks.
 @discussion This will be typically used by UI logic to cancel fetches during view reuse.
 */
- (void)cancelFetch;

@end

@interface HNKNetworkFetcher (Subclassing)

/**
 Returns the URL sessions used to download the image. Override to use a custom session. Uses sharedSession by default.
 */
@property (nonatomic, readonly) NSURLSession *URLSession;

@end
