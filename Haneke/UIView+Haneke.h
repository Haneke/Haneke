//
//  UIView+Haneke.h
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

extern const CGFloat HNKViewFormatCompressionQuality;
extern const unsigned long long HNKViewFormatDiskCapacity;

/**
 Convenience category used in the other UIKit categories to avoid repeating code. Intended for internal use.
 */
@interface UIView (Haneke)

@property (nonatomic, readonly) HNKScaleMode hnk_scaleMode;

@end

@interface HNKCache(UIView)

+ (void)registerSharedFormat:(HNKCacheFormat*)format;

+ (HNKCacheFormat*)sharedFormatWithSize:(CGSize)size scaleMode:(HNKScaleMode)scaleMode;

@end
