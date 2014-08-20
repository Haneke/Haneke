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

- (void)hnk_registerFormat:(HNKCacheFormat*)format;

- (HNKCacheFormat*)hnk_sharedFormatWithSize:(CGSize)size scaleMode:(HNKScaleMode)scaleMode;

@end
