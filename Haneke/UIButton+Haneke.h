//
//  UIButton+Haneke.h
//  Haneke
//
//  Created by Hermes Pique on 8/20/14.
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

#import <UIKit/UIKit.h>
#import "HNKCache.h"

@interface UIButton (Haneke)

#pragma mark Setting the content image

- (void)hnk_setImageFromURL:(NSURL*)URL forState:(UIControlState)state;

- (void)hnk_setImageFromURL:(NSURL*)URL forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage;

- (void)hnk_setImageFromURL:(NSURL*)URL forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;

- (void)hnk_setImageFromFile:(NSString*)path forState:(UIControlState)state;

- (void)hnk_setImageFromFile:(NSString*)path forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage;

- (void)hnk_setImageFromFile:(NSString*)path forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;

- (void)hnk_setImage:(UIImage*)image withKey:(NSString*)key forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;

- (void)hnk_setImageFromEntity:(id<HNKCacheEntity>)entity forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;

- (void)hnk_cancelSetImage;

@property (nonatomic, strong) HNKCacheFormat *hnk_imageCacheFormat;

#pragma mark Setting the background image

- (void)hnk_setBackgroundImageFromURL:(NSURL*)URL forState:(UIControlState)state;

- (void)hnk_setBackgroundImageFromURL:(NSURL*)URL forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage;

- (void)hnk_setBackgroundImageFromURL:(NSURL*)URL forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;

- (void)hnk_setBackgroundImageFromFile:(NSString*)path forState:(UIControlState)state;

- (void)hnk_setBackgroundImageFromFile:(NSString*)path forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage;

- (void)hnk_setBackgroundImageFromFile:(NSString*)path forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;

- (void)hnk_setBackgroundImage:(UIImage*)image withKey:(NSString*)key forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;

- (void)hnk_setBackgroundImageFromEntity:(id<HNKCacheEntity>)entity forState:(UIControlState)state placeholderImage:(UIImage*)placeholderImage success:(void (^)(UIImage *image))successBlock failure:(void (^)(NSError *error))failureBlock;

- (void)hnk_cancelSetBackgroundImage;

@property (nonatomic, strong) HNKCacheFormat *hnk_backgroundImageCacheFormat;

@end
