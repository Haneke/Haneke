//
//  UIImage+hnk_utils.m
//  Haneke
//
//  Created by Hermes on 30/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "UIImage+hnk_utils.h"

@implementation UIImage (hnk_utils)

- (CGRect)hnk_aspectFillRectForSize:(CGSize)size
{
    CGFloat targetAspect = size.width / size.height;
    CGFloat sourceAspect = self.size.width / self.size.height;
    CGRect rect = CGRectZero;
    
    if (targetAspect > sourceAspect)
    {
        rect.size.height = size.height;
        rect.size.width = rect.size.height * sourceAspect;
        rect.origin.x = (size.width - rect.size.width) * 0.5;
    }
    else
    {
        rect.size.height = size.height;
        rect.size.width = rect.size.height * sourceAspect;
        rect.origin.x = (size.width - rect.size.width) * 0.5;
    }
    return CGRectIntegral(rect);
}

- (CGRect)hnk_aspectFitRectForSize:(CGSize)size
{
    CGFloat targetAspect = size.width / size.height;
    CGFloat sourceAspect = self.size.width / self.size.height;
    CGRect rect = CGRectZero;
    
    if (targetAspect > sourceAspect)
    {
        rect.size.height = size.height;
        rect.size.width = rect.size.height * sourceAspect;
        rect.origin.x = (size.width - rect.size.width) * 0.5;
    }
    else
    {
        rect.size.width = size.width;
        rect.size.height = rect.size.width / sourceAspect;
        rect.origin.y = (size.height - rect.size.height) * 0.5;
    }
    return CGRectIntegral(rect);
}

- (UIImage *)hnk_imageByScalingToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
