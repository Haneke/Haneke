//
//  HNKDiskCache.h
//  Haneke
//
//  Created by Hermes Pique on 8/21/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
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
