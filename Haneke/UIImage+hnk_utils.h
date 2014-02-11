//
//  UIImage+hnk_utils.h
//  Haneke
//
//  Created by Hermes on 30/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (hnk_utils)

- (CGRect)hnk_aspectFillRectForSize:(CGSize)size;

- (CGRect)hnk_aspectFitRectForSize:(CGSize)size;

- (UIImage *)hnk_imageByScalingToSize:(CGSize)newSize;

@end
