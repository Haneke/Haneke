//
//  UIView+Haneke.m
//  Haneke
//
//  Created by Hermes Pique on 8/20/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "UIView+Haneke.h"
#import "HNKCache.h"
#import <objc/runtime.h>

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
            return HNKScaleModeFill;
    }
}

- (void)hnk_registerFormat:(HNKCacheFormat*)format
{
    HNKCache *cache = [HNKCache sharedCache];
    if (cache.formats[format.name] != format)
    {
        [[HNKCache sharedCache] registerFormat:format];
    }
}

- (HNKCacheFormat*)hnk_sharedFormatWithSize:(CGSize)size scaleMode:(HNKScaleMode)scaleMode
{
    NSString *scaleModeName = NSStringFromHNKScaleMode(scaleMode);
    NSString *name = [NSString stringWithFormat:@"auto-%ldx%ld-%@", (long)size.width, (long)size.height, scaleModeName];
    HNKCache *cache = [HNKCache sharedCache];
    HNKCacheFormat *format = cache.formats[name];
    if (!format)
    {
        format = [[HNKCacheFormat alloc] initWithName:name];
        format.size = size;
        format.diskCapacity = 10 * 1024 * 1024;
        format.allowUpscaling = YES;
        format.compressionQuality = 0.75;
        format.scaleMode = scaleMode;
        [cache registerFormat:format];
    }
    return format;
}

@end
