//
//  UIView+Haneke.m
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

#import "UIView+Haneke.h"
#import "HNKCache.h"
#import <objc/runtime.h>

const CGFloat HNKViewFormatCompressionQuality = 0.75;
const unsigned long long HNKViewFormatDiskCapacity = 10 * 1024 * 1024;

static NSString *NSStringFromHNKScaleMode(HNKScaleMode scaleMode)
{
    switch (scaleMode) {
        case HNKScaleModeFill:
            return @"fill";
        case HNKScaleModeAspectFill:
            return @"aspectfill";
        case HNKScaleModeAspectFit:
            return @"aspectfit";
        case HNKScaleModeNone:
            return @"scalenone";
    }
    return nil;
}

@implementation UIView (Haneke)

- (HNKScaleMode)hnk_scaleMode
{
    switch (self.contentMode) {
        case UIViewContentModeScaleToFill:
            return HNKScaleModeFill;
        case UIViewContentModeScaleAspectFit:
            return HNKScaleModeAspectFit;
        case UIViewContentModeScaleAspectFill:
            return HNKScaleModeAspectFill;
        case UIViewContentModeRedraw:
        case UIViewContentModeCenter:
        case UIViewContentModeTop:
        case UIViewContentModeBottom:
        case UIViewContentModeLeft:
        case UIViewContentModeRight:
        case UIViewContentModeTopLeft:
        case UIViewContentModeTopRight:
        case UIViewContentModeBottomLeft:
        case UIViewContentModeBottomRight:
            return HNKScaleModeNone;
    }
}

@end

@implementation HNKCache(UIView)

+ (void)registerSharedFormat:(HNKCacheFormat*)format
{
    HNKCache *cache = [HNKCache sharedCache];
    if (cache.formats[format.name] != format)
    {
        [[HNKCache sharedCache] registerFormat:format];
    }
}

+ (HNKCacheFormat*)sharedFormatWithSize:(CGSize)size scaleMode:(HNKScaleMode)scaleMode
{
    NSString *scaleModeName = NSStringFromHNKScaleMode(scaleMode);
    NSString *name = [NSString stringWithFormat:@"auto-%ldx%ld-%@", (long)size.width, (long)size.height, scaleModeName];
    HNKCache *cache = [HNKCache sharedCache];
    HNKCacheFormat *format = cache.formats[name];
    if (!format)
    {
        format = [[HNKCacheFormat alloc] initWithName:name];
        format.size = size;
        format.diskCapacity = HNKViewFormatDiskCapacity;
        format.allowUpscaling = YES;
        format.compressionQuality = HNKViewFormatCompressionQuality;
        format.scaleMode = scaleMode;
        [cache registerFormat:format];
    }
    return format;
}

@end
