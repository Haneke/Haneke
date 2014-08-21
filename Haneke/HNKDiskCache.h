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

@interface HNKDiskCache : NSObject

@property (nonatomic, readonly) unsigned long long size;

@property (nonatomic, assign) unsigned long long capacity;

@property (nonatomic, readonly) dispatch_queue_t queue;

- (instancetype)initWithDirectory:(NSString*)directory capacity:(unsigned long long)capacity;

- (void)setData:(NSData*)data forKey:(NSString*)key;

- (void)fetchDataForKey:(NSString*)key success:(void (^)(NSData *data))successBlock failure:(void (^)(NSError *error))failureBlock;

- (void)removeDataForKey:(NSString*)key;

- (void)removeAllData;

- (void)enumerateDataByAccessDateUsingBlock:(void(^)(NSString *key, NSData *data, NSDate *accessDate, BOOL *stop))block;

- (void)updateAccessDateForKey:(NSString*)key data:(NSData* (^)())lazyData ;

@end
