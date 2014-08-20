//
//  UIView+Haneke.h
//  Haneke
//
//  Created by Hermes Pique on 8/20/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HNKCache.h"

@interface UIView (Haneke)

@property (nonatomic, readonly) HNKScaleMode hnk_scaleMode;

@end

@interface HNKCache(UIView)

+ (void)registerSharedFormat:(HNKCacheFormat*)format;

+ (HNKCacheFormat*)sharedFormatWithSize:(CGSize)size scaleMode:(HNKScaleMode)scaleMode;

@end
