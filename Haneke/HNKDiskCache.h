//
//  HNKDiskCache.h
//  Haneke
//
//  Created by Hermes Pique on 8/21/14.
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

/**
 A least-recently-used disk cache for data that performs all of its operations asynchronously in its own queue. The least recently used data is automatically deleted from disk when the cache capacity is reached.
 @discussion HNKDiskCache is a generic-purpose disk cache and can be used independently of the rest of Haneke.
 */
@interface HNKDiskCache : NSObject

#pragma mark Initializing the cache
///---------------------------------------------
/// @name Initializing the cache
///---------------------------------------------

/**
 Initializes a cache with the given directory and capacity. Upon being initialized the cache will inmmediately calculate its size and, if needed to keep it below capacity, delete the least recently used data.
 @param directory Path of an existing directory in which the cache will write data. Once initialized you should not read and write to this directory.
 @param capacity Capacity in bytes. If the cache size exceeds its capacity the least recently used data will be deleted until it doesn't.
 */
- (instancetype)initWithDirectory:(NSString*)directory capacity:(unsigned long long)capacity;

/**
 Cache capacity in bytes. If the cache size exceeds its capacity the least recently used data will be deleted until it doesn't.
 */
@property (nonatomic, assign) unsigned long long capacity;

/**
 Cache size in bytes. If the cache size exceeds its capacity the least recently used data will be deleted until it doesn't.
 */
@property (nonatomic, readonly) unsigned long long size;

/**
 Serial queue used by the cache to perform all of its operations asynchronously.
 @discussion Blocks dispatched in this queue will always run after the previous cache operation has completed.
 */
@property (nonatomic, readonly) dispatch_queue_t queue;

#pragma mark Setting and fetching data
///---------------------------------------------
/// @name Setting and fetching data
///---------------------------------------------

/**
 Asynchronously sets the given data for the given key. Upon completition the cache size will be updated.
 @param data Data to be cached.
 @param key Key to be associated with the data.
 @discussion If the cache size exceeds its capacity the least recently used data will be deleted until it doesn't.
 */
- (void)setData:(NSData*)data forKey:(NSString*)key;

/**
 Fetches the data associated with the given key and updates its access date.
 @param key Key associated with requested data.
 @param successBlock Block to be called with the requested data. Always called from the main queue.
 @param failureBlock Block to be called if there is no data associated with the given key or, less likely, if there is an error while reading the data. Always called from the main queue. If no data is found the error will be NSFileReadNoSuchFileError.
 */
- (void)fetchDataForKey:(NSString*)key success:(void (^)(NSData *data))successBlock failure:(void (^)(NSError *error))failureBlock;

#pragma mark Removing data
///---------------------------------------------
/// @name Removing data
///---------------------------------------------

/**
 Asynchronously removes the data for the given key. Upon completition the cache size will be updated.
 @param key Key associated with the data to be removed.
 */
- (void)removeDataForKey:(NSString*)key;

/**
 Asynchronously removes all data from the cache. Upon completition the cache size will be zero.
 */
- (void)removeAllData;

#pragma mark Managing data by access date
///---------------------------------------------
/// @name Managing data by access date
///---------------------------------------------

/**
 Asynchronously enumerates all key-data pairs in the cache by access date in descending order.
 @param block Block to apply to elements in the array. Called from the cache queue.
 */
- (void)enumerateDataByAccessDateUsingBlock:(void(^)(NSString *key, NSData *data, NSDate *accessDate, BOOL *stop))block;

/**
 Asynchronously updates the access date for the given key.
 @param key Key associated with the data whose access date will be updated.
 @param lazyData Block to be called if there is no data associated with the given key, in which case it must return it. Called from the cache queue.
 @discussion Calling this method is equivalent to calling setData:forKey: with the difference that the data is only requested if it isn't already cached.
 */
- (void)updateAccessDateForKey:(NSString*)key data:(NSData* (^)())lazyData ;

@end
