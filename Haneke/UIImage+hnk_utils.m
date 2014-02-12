//
//  UIImage+hnk_utils.m
//  Haneke
//
//  Created by Hermes on 30/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "UIImage+hnk_utils.h"

@implementation UIImage (hnk_utils)

- (CGSize)hnk_aspectFillSizeForSize:(CGSize)size
{
    CGFloat targetAspect = size.width / size.height;
    CGFloat sourceAspect = self.size.width / self.size.height;
    CGSize result = CGSizeZero;
    
    if (targetAspect > sourceAspect)
    {
        result.height = size.height;
        result.width = result.height * sourceAspect;
    }
    else
    {
        result.height = size.height;
        result.width = result.height * sourceAspect;
    }
    return CGSizeMake(ceil(result.width), ceil(result.height));
}

- (CGSize)hnk_aspectFitSizeForSize:(CGSize)size
{
    CGFloat targetAspect = size.width / size.height;
    CGFloat sourceAspect = self.size.width / self.size.height;
    CGSize result = CGSizeZero;
    
    if (targetAspect > sourceAspect)
    {
        result.height = size.height;
        result.width = result.height * sourceAspect;
    }
    else
    {
        result.width = size.width;
        result.height = result.width / sourceAspect;
    }
    return CGSizeMake(ceil(result.width), ceil(result.height));
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
